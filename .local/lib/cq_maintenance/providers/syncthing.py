import json,os,time,ssl,urllib.request,urllib.parse,urllib.error,xml.etree.ElementTree as ET
from pathlib import Path
from ..model import now
from ..util import Problem,read_json,atomic_json,require
from .base import action

class Client:
    def __init__(self,ctx):
        self.ctx=ctx
        self.deadline=time.monotonic()+(ctx.config.timeout if ctx.checking else ctx.options.get('repair_timeout',900))
        self.request_timeout=5 if ctx.checking else ctx.options.get('scan_timeout',300)
        candidates=[Path(ctx.options['config']).expanduser()] if ctx.options.get('config') else [Path.home()/'.local/state/syncthing/config.xml',Path.home()/'.config/syncthing/config.xml']
        path=next((p for p in candidates if p.is_file()),None)
        if path is None:raise Problem('Syncthing configuration not found')
        gui=ET.parse(path).getroot().find('gui')
        if gui is None:raise Problem('Syncthing GUI/API is not configured')
        address=gui.findtext('address','127.0.0.1:8384')
        if address.startswith('0.0.0.0:'):address='127.0.0.1:'+address.rsplit(':',1)[1]
        self.url=ctx.options.get('url',('https' if gui.get('tls')=='true' else 'http')+'://'+address)
        parsed=urllib.parse.urlsplit(self.url)
        if parsed.hostname not in ('localhost','127.0.0.1','::1') or parsed.username or parsed.password:raise Problem('Only a local Syncthing API endpoint is supported')
        self.key=Path(ctx.options['key_file']).expanduser().read_text().strip() if ctx.options.get('key_file') else gui.findtext('apikey','')
        self.tls=ssl.create_default_context(cafile=ctx.options.get('ca_file'))
    def request(self,endpoint,method='GET',**query):
        url=self.url+'/rest/'+endpoint
        if query:url+='?'+urllib.parse.urlencode(query)
        remaining=self.deadline-time.monotonic()
        if remaining<=0:raise Problem('Syncthing check deadline exceeded')
        req=urllib.request.Request(url,headers={'X-API-Key':self.key},method=method)
        try:
            with urllib.request.urlopen(req,timeout=min(self.request_timeout,remaining),context=self.tls) as response:
                body=response.read()
                return json.loads(body) if body else {}
        except urllib.error.HTTPError as error:
            raise Problem(f'Local Syncthing API returned HTTP {error.code}; inspect folder/service state') from None
        except TimeoutError:
            raise Problem('Syncthing API timed out; a requested scan may still be running') from None
        except Exception:raise Problem('Local Syncthing API request failed (service, TLS or authentication)')

def conflict_scan(ctx,folders):
    path=ctx.state('conflicts.json');old=read_json(path,{})
    if not ctx.force and old.get('complete') and now()-old.get('checked_at',0)<3600:return old
    if ctx.force or not old or old.get('complete'):
        queue=[[str(Path(folder['path']).expanduser()),0] for folder in folders if not folder.get('paused')];found=[]
    else:queue=old.get('queue',[]);found=old.get('found',[])
    deadline=time.monotonic()+2;budget=30000;processed=0;errors=old.get('errors',[]) if not old.get('complete') else []
    while queue and processed<budget and time.monotonic()<deadline:
        directory,offset=queue.pop()
        p=Path(directory)
        if p.is_symlink():continue
        try:
            with os.scandir(p) as entries:
                for index,entry in enumerate(entries):
                    if index<offset:continue
                    if processed>=budget or time.monotonic()>=deadline:
                        queue.append([directory,index]);break
                    processed+=1
                    if entry.is_symlink():continue
                    if '.sync-conflict-' in entry.name and entry.is_file(follow_symlinks=False):
                        if len(found)<100:found.append(entry.path)
                    if entry.is_dir(follow_symlinks=False) and entry.name not in ('.stversions','.git','.stfolder'):queue.append([entry.path,0])
        except OSError:
            if directory not in errors:errors.append(directory)
    result={'queue':queue,'found':found,'errors':errors,'complete':not queue,'checked_at':now()}
    # Keep previous confirmed findings until a complete pass can clear them.
    result['visible_found']=sorted(set(found+(old.get('visible_found',[]) if queue else [])))
    atomic_json(path,result);return result

def check(ctx):
    actions=[action('Request folder scans'),action('Open Syncthing',False,'open'),action('Restart Syncthing service',False,'restart')]
    try:
        api=Client(ctx);api.request('system/status')
        folders=api.request('config/folders')
        folders=[f for f in folders if f['id'] not in ctx.options.get('ignore_folders',[])]
        if ctx.options.get('folders'):folders=[f for f in folders if f['id'] in ctx.options['folders']]
        connections=api.request('system/connections').get('connections',{})
        connected=[id for id,data in connections.items() if data.get('connected')]
        aggregate=api.request('db/completion');need=aggregate.get('needItems',0)
        remote_need=sum(api.request('db/completion',device=id).get('needItems',0) for id in connected)
    except Problem as error:return ctx.result('error',str(error),actions=actions[1:])
    previous=read_json(ctx.state('progress.json'),{})
    metric=need+remote_need
    progress=now() if metric!=previous.get('pending') else previous.get('progress_at',now())
    offline=previous.get('offline_since',now()) if not connected else None
    atomic_json(ctx.state('progress.json'),{'pending':metric,'progress_at':progress,'offline_since':offline})
    details=[];errors=0
    cache=read_json(ctx.state('folders.json'),{})
    if ctx.force or now()-cache.get('checked_at',0)>300:
        states={folder['id']:api.request('db/status',folder=folder['id']) for folder in folders if not folder.get('paused')}
        cache={'checked_at':now(),'states':states};atomic_json(ctx.state('folders.json'),cache)
    for folder in folders:
        data=cache.get('states',{}).get(folder['id'],{})
        label=folder.get('label') or folder['id']
        if folder.get('paused'):details.append(label+': paused (not automatically resumed)');continue
        count=data.get('pullErrors',0)
        if count or data.get('state')=='error':errors+=1;details.append(label+': folder errors')
        elif data.get('needTotalItems',0):
            suffix=' remote changes (send-only; review before overriding)' if folder.get('type')=='sendonly' else ' pending'
            details.append(label+f': {data["needTotalItems"]}'+suffix)
    scan=conflict_scan(ctx,folders);conflicts=scan.get('visible_found',[])
    if conflicts:details.extend(conflicts[:20])
    partial=not scan.get('complete') or bool(scan.get('errors'))
    required=ctx.options.get('required_peers',[])
    missing=[id for id in required if id not in connected]
    state='error' if errors else 'warning' if conflicts or (metric and now()-progress>1800) else 'pending' if metric else 'unknown' if partial or not connected or missing else 'ok'
    if not connected:details.append('No connected peers; remote freshness cannot be confirmed.')
    if missing:details.append('An expected peer is offline.')
    if partial:details.append('Conflict-file scan incomplete; previous findings retained.')
    conflict_label=str(len(conflicts))+('+' if len(conflicts)>=100 else '')
    summary=f'{len(folders)} folders · {len(connected)} peers · {metric} pending · {conflict_label} conflicts'
    activities={data.get('state') for data in cache.get('states',{}).values()}
    activity='syncing' if 'syncing' in activities else 'scanning' if 'scanning' in activities else ''
    return ctx.result(state,summary,details=details,metrics={'pending':metric,'folders':len(folders),'connected':len(connected),'progress_at':progress,'offline_since':offline,'conflicts':len(conflicts)},actions=actions,activity=activity)
def execute(ctx,id):
    if id=='restart':
        require(ctx.run(['systemctl','--user','restart','syncthing.service'],foreground=True,timeout=60));return 'Restart requested'
    api=Client(ctx);folders=api.request('config/folders')
    failures=[];completed=0
    for folder in folders:
        if folder.get('paused') or folder['id'] in ctx.options.get('ignore_folders',[]):continue
        if ctx.options.get('folders') and folder['id'] not in ctx.options['folders']:continue
        try:
            api.request('db/scan','POST',folder=folder['id']);completed+=1
        except Problem as error:
            failures.append((folder.get('label') or folder['id'])+': '+str(error))
    if failures:raise Problem(f'{completed} folder scans completed; '+'; '.join(failures))
    return f'{completed} folder scans completed; remote delivery must be confirmed by subsequent checks'
def open(ctx):return ['xdg-open',Client(ctx).url]
