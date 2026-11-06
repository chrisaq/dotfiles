#!/usr/bin/env python3
"""Read-only planning and guarded transfers for crypt-sync; no secret bodies in output."""
from __future__ import annotations
import argparse,contextlib,fcntl,hashlib,json,os,stat,subprocess,sys,tempfile,time
from pathlib import Path

class Blocked(Exception):pass

def root():return Path(os.environ.get('XDG_STATE_HOME') or Path.home()/'.local/state')/'crypt-sync'
def ledger():
    try:return json.loads((root()/'verified.json').read_text())
    except (OSError,ValueError):return {'entries':{}}
def save(data):
    directory=root();directory.mkdir(parents=True,exist_ok=True,mode=0o700)
    fd,name=tempfile.mkstemp(dir=directory,prefix='.verified-')
    try:
        with os.fdopen(fd,'w') as stream:os.fchmod(stream.fileno(),0o600);json.dump(data,stream)
        os.replace(name,directory/'verified.json')
    finally:Path(name).unlink(missing_ok=True)

@contextlib.contextmanager
def locked(name='run.lock'):
    directory=root();directory.mkdir(parents=True,exist_ok=True,mode=0o700)
    fd=os.open(directory/name,os.O_CREAT|os.O_RDWR|os.O_NOFOLLOW,0o600)
    try:
        try:fcntl.flock(fd,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:raise Blocked('Another crypt-sync operation is running')
        yield
    finally:os.close(fd)

def fingerprint(path):
    try:info=path.lstat()
    except FileNotFoundError:return None
    if not stat.S_ISREG(info.st_mode):raise Blocked('Symlink or nonregular path refused')
    flags=os.O_RDONLY|os.O_NOFOLLOW
    fd=os.open(path,flags)
    try:
        with os.fdopen(fd,'rb') as stream:
            before=os.fstat(stream.fileno());digest=hashlib.file_digest(stream,'sha256').hexdigest();after=os.fstat(stream.fileno())
        current=path.lstat()
        if (before.st_ino,before.st_size,before.st_mtime_ns)!=(after.st_ino,after.st_size,after.st_mtime_ns) or (current.st_ino,current.st_mtime_ns)!=(after.st_ino,after.st_mtime_ns):raise Blocked('File changed during inspection')
        return {'sha':digest,'mtime_ns':after.st_mtime_ns,'size':after.st_size}
    except Exception:raise

def mappings():
    directory=Path(os.environ.get('XDG_BIN_HOME') or Path.home()/'.local/bin')/'crypt-sync'
    store=Path(os.environ.get('PASSWORD_STORE_DIR') or Path.home()/'Sync/Password-Store')/'ConfigFiles'
    result=[];seen=set();targets=set()
    for listing in sorted(directory.glob('crypt-sync-list*.txt')):
        for line in listing.read_text().splitlines():
            if not line or line.startswith('#'):continue
            if ':' not in line:raise Blocked('Malformed mapping in '+listing.name)
            encrypted,local=line.split(':',1)
            # Paths are home/store-relative; nested encrypted names are permitted.
            if not encrypted or not local or any(Path(p).is_absolute() or '..' in Path(p).parts for p in (encrypted,local)):raise Blocked('Invalid mapping path')
            if encrypted in seen or local in targets:raise Blocked('Duplicate crypt-sync mapping')
            seen.add(encrypted);targets.add(local)
            if (Path.home()/local).resolve()==(store/encrypted).resolve():raise Blocked('Local and vault paths must differ')
            result.append((encrypted,Path.home()/local,store/encrypted))
    return result

def key(local,vault):return str(local)+'\0'+str(vault)
def inspect(name,local,vault,data,guarded=False):
    row={'name':name,'local':str(local),'vault':str(vault)}
    try:
        a=fingerprint(local);b=fingerprint(vault);baseline=data.get('entries',{}).get(key(local,vault))
        if a is None and b is None:state='missing'
        elif a is None:state='decrypt'
        elif b is None:state='encrypt'
        elif not guarded:
            state='encrypt' if a['mtime_ns']>b['mtime_ns'] else 'decrypt' if a['mtime_ns']<b['mtime_ns'] else 'ok'
        elif baseline is None:state='unverified'
        else:
            changed_a=a['sha']!=baseline['local'];changed_b=b['sha']!=baseline['vault']
            state='conflict' if changed_a and changed_b else 'encrypt' if changed_a else 'decrypt' if changed_b else 'ok'
        row.update(state=state,local_fingerprint=a,vault_fingerprint=b)
    except (OSError,Blocked):row.update(state='invalid')
    return row

def status(guarded=False):
    data=ledger()
    return {'schema_version':1,'last_success':data.get('last_success'),'entries':[inspect(n,a,b,data,guarded=guarded) for n,a,b in mappings()]}

def record(local,vault,source=None,expected=None,destination=None,expected_dest=None):
    a=fingerprint(local);b=fingerprint(vault)
    if not a or not b:return
    if source:
        current=fingerprint(source)
        if not current or current['sha']!=expected:return
    if destination:
        current=fingerprint(destination)
        if not current or current['sha']!=expected_dest:return
    with locked('state.lock'):
        data=ledger();data.setdefault('entries',{})[key(local,vault)]={'local':a['sha'],'vault':b['sha'],'verified_at':time.time()};save(data)

def gpg(args,**kwargs):
    command=['gpg','--quiet']
    if not sys.stdin.isatty():command+=['--batch','--pinentry-mode','error']
    try:return subprocess.run(command+args,capture_output=True,timeout=120,**kwargs)
    except (OSError,subprocess.TimeoutExpired):raise Blocked('GPG unavailable or timed out')

def verify(local,vault):
    a=fingerprint(local);b=fingerprint(vault)
    response=gpg(['--decrypt',str(vault)])
    if response.returncode:raise Blocked('GPG decryption failed; check key availability, card access and unlock state')
    matches=hashlib.sha256(response.stdout).hexdigest()==a['sha']
    del response
    if fingerprint(local)!=a or fingerprint(vault)!=b:raise Blocked('File changed during verification')
    if matches:record(local,vault,local,a['sha'],vault,b['sha'])
    return matches

def transfer(local,vault,direction):
    a=fingerprint(local);b=fingerprint(vault)
    source,destination=(local,vault) if direction=='encrypt' else (vault,local)
    source_fp=a if direction=='encrypt' else b
    destination.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    fd,name=tempfile.mkstemp(dir=destination.parent,prefix='.crypt-sync-guarded-');os.close(fd)
    try:
        args=['--yes','--output',name]
        args+=['--encrypt','--armor','--recipient','0xAEE3FD309AFCC09E'] if direction=='encrypt' else ['--decrypt']
        response=gpg(args+[str(source)])
        if response.returncode:raise Blocked('GPG transfer failed; unlock or review credentials')
        if fingerprint(local)!=a or fingerprint(vault)!=b:raise Blocked('File changed since planning; replacement refused')
        output_sha=fingerprint(Path(name))['sha']
        os.chmod(name,0o600);os.utime(name,ns=(source_fp['mtime_ns'],source_fp['mtime_ns']));os.replace(name,destination)
        record(local,vault,source,source_fp['sha'],destination,output_sha)
    finally:Path(name).unlink(missing_ok=True)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true');parser.add_argument('--json',action='store_true');parser.add_argument('--safe',action='store_true');parser.add_argument('--verify',action='store_true')
    parser.add_argument('--resolve');parser.add_argument('--prefer',choices=['local','vault']);parser.add_argument('--fingerprint');parser.add_argument('--record',nargs=6,metavar=('LOCAL','VAULT','SOURCE','SHA','DEST','DEST_SHA'));parser.add_argument('--record-run',type=int)
    args=parser.parse_args()
    if args.fingerprint:
        print(fingerprint(Path(args.fingerprint))['sha']);return 0
    if args.record:
        a,b,source,sha,destination,dest_sha=args.record;record(Path(a),Path(b),Path(source),sha,Path(destination),dest_sha);return 0
    if args.record_run is not None:
        with locked('state.lock'):
            data=ledger();data['last_attempt']=time.time();data['last_exit']=args.record_run
            if args.record_run==0:data['last_success']=time.time()
            save(data)
        return 0
    if args.check:
        data=status();print(json.dumps(data) if args.json else '\n'.join(row['name']+': '+row['state'] for row in data['entries']));return 0
    if not (args.safe or args.verify or args.resolve):parser.error('Select --check, --safe, --verify or --resolve')
    with locked():
        blocked=0;found=False
        for name,local,vault in mappings():
            if args.resolve and name!=args.resolve:continue
            found=True
            try:
                row=inspect(name,local,vault,ledger(),guarded=True);state=row['state']
                if args.resolve:
                    if not args.prefer:raise Blocked('Choose --prefer local or vault explicitly')
                    transfer(local,vault,'encrypt' if args.prefer=='local' else 'decrypt')
                elif state=='unverified':
                    if not verify(local,vault):raise Blocked('Copies differ without a verified baseline; choose a source explicitly')
                elif state in ('encrypt','decrypt') and not args.verify:transfer(local,vault,state)
                elif state in ('conflict','invalid'):raise Blocked('Independent changes or invalid paths; review required')
                print(name+': '+('verified' if state=='unverified' else state))
            except (Blocked,OSError) as error:
                reason=str(error) if isinstance(error,Blocked) else 'File access failed; check paths and permissions'
                blocked+=1;print(name+': blocked; '+reason,file=sys.stderr)
        if args.resolve and not found:raise Blocked('Unknown mapping name')
        with locked('state.lock'):
            data=ledger();data['last_attempt']=time.time();data['last_exit']=1 if blocked else 0
            if not blocked:data['last_success']=time.time()
            save(data)
        return 1 if blocked else 0

if __name__=='__main__':
    try:raise SystemExit(main())
    except (Blocked,OSError,ValueError) as error:
        print('crypt-sync: operation blocked ('+type(error).__name__+'); inspect configuration or retry',file=sys.stderr);raise SystemExit(1)
