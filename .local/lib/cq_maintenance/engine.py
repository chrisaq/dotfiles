from __future__ import annotations
import concurrent.futures,hashlib
from pathlib import Path
from .model import Result,now
from .config import load
from .providers import get
from .providers.base import Context
from .util import Problem,atomic_json,read_json,state_dir,lock,signal_bar


def result_path(id):return state_dir()/'results'/(id+'.json')
def previous(id):
    try:return Result.model_validate(read_json(result_path(id)))
    except Exception:return None

def snapshot(settings=None,include_disabled=False):
    settings=settings or load();results=[]
    for id,config in settings.checks.items():
        if not config.enabled:
            if include_disabled:results.append(Result(id=id,state='disabled',summary='Disabled on this machine'))
            continue
        item=previous(id) or Result(id=id,state='unknown',summary='Not checked yet',checked_at=0)
        if config.provider=='mail':
            from .providers.mail import overlay
            item=overlay(Context(id,config,item),item)
        if now()-item.checked_at>max(180,config.interval*3):
            item.stale=True
            if item.state not in ('error','warning') and not (config.provider=='mail' and item.activity):item.state='unknown'
            item.details.insert(0,'Observation is stale; run a check.')
        job=read_json(state_dir()/'jobs'/(id+'.json'),{})
        if job.get('active') and now()-job.get('started_at',0)<job.get('timeout',3600):item.activity=job.get('activity','running')
        results.append(item)
    monitor=read_json(state_dir()/'collector.json',{})
    from .provision.units import bootstrap_hint
    hint=bootstrap_hint(settings)
    if hint:
        results.insert(0,Result(id='monitor',state='warning',summary=hint,details=['Run cq_maintenance setup or open the Setup checklist.']))
    elif results and now()-monitor.get('heartbeat',0)>180:
        results.insert(0,Result(id='monitor',state='unknown',summary='Collector has not run recently',checked_at=monitor.get('heartbeat',0),stale=True))
    from .provision.core import visible
    results.extend(visible(settings))
    return results

def save(result):
    atomic_json(result_path(result.id),result.model_dump())

def notify_bar():
    # A bar/configuration problem must not turn a completed repair into failure.
    try:signal_bar(load().waybar_signal)
    except Exception:pass

def job(id,active,activity='checking',timeout=180):
    atomic_json(state_dir()/'jobs'/(id+'.json'),{'active':active,'activity':activity,'started_at':now(),'timeout':timeout})
    if active and activity=='fixing':notify_bar()

def check_one(id,config,force=False):
    result=_check_one(id,config,force)
    # Publish after the result is written and its checking flag is cleared.
    # Another slow provider must not delay this provider's UI update.
    notify_bar()
    return result

def _check_one(id,config,force=False):
    old=previous(id)
    try:
        with lock(id):
            job(id,True,timeout=config.timeout+30)
            try:
                result=get(config.provider).check(Context(id,config,old,force))
                save(result)
            finally:job(id,False)
        return result
    except Problem as error:
        if 'already running' in str(error):return old or Result(id=id,state='unknown',summary=str(error))
        result=Result(id=id,state='unknown',summary=str(error),last_success=old.last_success if old else None)
    except Exception as error:
        # Backend errors can contain tokens/headers; retain only the exception type.
        result=Result(id=id,state='unknown',summary='Check failed ('+type(error).__name__+')',last_success=old.last_success if old else None)
    save(result);return result

def collect(ids=None,due=False):
    settings=load()
    requested=set(ids or [])
    unknown=requested-settings.checks.keys()
    if unknown:raise Problem('Unknown checks: '+', '.join(sorted(unknown)))
    with lock('collector'):
        atomic_json(state_dir()/'collector.json',{'heartbeat':now(),'running':True})
        work=[]
        for id,config in settings.checks.items():
            if not config.enabled or requested and id not in requested:continue
            old=previous(id)
            if due and old and now()-old.checked_at<config.interval:
                try:
                    invalidated=getattr(get(config.provider),'invalidated',None)
                    changed=callable(invalidated) and invalidated(config,old)
                except Exception:changed=True
                if not changed:continue
            work.append((id,config))
        with concurrent.futures.ThreadPoolExecutor(max_workers=settings.max_workers) as executor:
            futures=[executor.submit(check_one,id,config,not due) for id,config in work]
            for future in concurrent.futures.as_completed(futures):
                future.result();atomic_json(state_dir()/'collector.json',{'heartbeat':now(),'running':True})
        atomic_json(state_dir()/'collector.json',{'heartbeat':now(),'running':False})
    from .provision.core import inspect_one
    for setup_id,item in settings.setup.items():
        if item.enabled and item.waybar:inspect_one(setup_id,settings,True)
    signal_bar(settings.waybar_signal)
    return snapshot(settings)

def plans(ids=None):
    settings=load();requested=set(ids or [])
    if requested-settings.checks.keys():raise Problem('Unknown check ID')
    return [(id,config,previous(id)) for id,config in settings.checks.items() if config.enabled and (not requested or id in requested)]

def log_event(data):
    path=state_dir()/'actions.json'
    rows=read_json(path,[])
    rows=[row for row in rows if now()-row.get('at',0)<7*86400][-199:]
    atomic_json(path,rows+[dict(data,at=now())])

def source_signature():
    paths=[Path.home()/'.local/bin/cq_maintenance']+list((Path.home()/'.local/lib/cq_maintenance').rglob('*.py'))
    from .config import config_path
    paths += [config_path(),config_path().with_name('config.local.toml')]
    digest=hashlib.sha256()
    for path in sorted(paths):
        try:digest.update(str(path).encode());digest.update(path.read_bytes())
        except OSError:pass
    return digest.hexdigest()

def fix(ids=None,action_id='fix',dry_run=False):
    settings=load();rows=[]
    # Refuse concurrent fix batches; checks remain independent and share provider locks.
    with lock('repairs'):
        items=plans(ids)
        order={'git':0,'crypt':2,'mail_setup':3,'mail':4,'pass_sync':4,'syncthing':5}
        items.sort(key=lambda item:order.get(item[1].provider,6))
        setup_blocked=False;crypt_blocked=False
        source_before=source_signature()
        for id,config,old in items:
            if config.provider=='mail' and (setup_blocked or crypt_blocked):
                rows.append({'id':id,'state':'blocked','message':'Resolve mail setup or crypt settings first'});continue
            if source_signature()!=source_before:
                rows.append({'id':'monitor','state':'blocked','message':'Tool/configuration changed; rerun Fix all with the updated code'});break
            current=check_one(id,config)
            if config.provider=='crypt':
                entries=current.metrics.get('entries')
                crypt_blocked=entries is None or any(row.get('local','').endswith('/.config/mutt/settings.json') and row.get('state') not in ('ok','missing') for row in entries)
            selected=next((a for a in current.actions if a.id==action_id),None)
            if config.provider=='mail_setup' and (current.state=='unknown' or current.metrics.get('missing_prerequisites')):
                setup_blocked=True
            if selected is None or (not ids and not selected.safe):
                rows.append({'id':id,'state':'skipped','message':'No applicable safe action','remaining':current.state});continue
            if dry_run:
                rows.append({'id':id,'state':'planned','message':selected.label,'safe':selected.safe});continue
            outcome='completed';message=''
            try:
                with lock(id):
                    job(id,True,'fixing',3600)
                    try:message=get(config.provider).execute(Context(id,config,current,checking=False),action_id)
                    finally:job(id,False)
            except Exception as error:
                outcome='blocked';message=str(error) if isinstance(error,Problem) else 'Action failed ('+type(error).__name__+')'
                if config.provider=='mail_setup':setup_blocked=True
            updated=check_one(id,config,force=True)
            if config.provider=='mail' and outcome=='completed':
                # A successful mail repair may also clear its systemd failure.
                for monitor_id,monitor_config in settings.checks.items():
                    if monitor_config.enabled and monitor_config.provider=='units':
                        check_one(monitor_id,monitor_config,force=True)
            if config.provider=='crypt':
                # Only block dependent mail when the shared mail-settings entry is unresolved.
                crypt_blocked=updated.metrics.get('entries') is None or any(row.get('local','').endswith('/.config/mutt/settings.json') and row.get('state') not in ('ok','missing') for row in updated.metrics.get('entries',[]))
            row={'id':id,'state':outcome,'message':message,'remaining':updated.state};rows.append(row);log_event(row)
        # Outgoing encryption can generate new Syncthing work; its scan is deliberately last.
    signal_bar(settings.waybar_signal);return rows
