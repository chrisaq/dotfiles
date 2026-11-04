from __future__ import annotations
import contextlib, fcntl, json, os, signal, stat, subprocess, tempfile
from pathlib import Path
from .config import xdg

class Problem(Exception): pass

def atomic_text(path, text):
    path=Path(path)
    app_state=state_dir()
    if path.is_relative_to(app_state):
        app_state.mkdir(parents=True,exist_ok=True,mode=0o700)
        info=app_state.lstat()
        if not stat.S_ISDIR(info.st_mode) or info.st_uid!=os.getuid():raise Problem('Unsafe state directory')
        app_state.chmod(0o700)
    path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    fd,tmp=tempfile.mkstemp(prefix='.'+path.name+'-',dir=path.parent)
    try:
        with os.fdopen(fd,'w') as stream:
            os.fchmod(stream.fileno(),0o600);stream.write(text)
        os.replace(tmp,path)
    finally:
        Path(tmp).unlink(missing_ok=True)

def atomic_json(path, data): atomic_text(path,json.dumps(data,ensure_ascii=False,indent=2)+'\n')

def read_json(path, default=None):
    try:return json.loads(Path(path).read_text())
    except (OSError,ValueError):return default

def state_dir(): return xdg('state')/'cq/maintenance'
def cache_dir(): return xdg('cache')/'cq/maintenance'

def runtime_dir():
    for value in (os.environ.get('XDG_RUNTIME_DIR',''),f'/run/user/{os.getuid()}'):
        p=Path(value)
        if not value or not p.is_absolute():continue
        try:
            info=p.lstat()
            if stat.S_ISDIR(info.st_mode) and info.st_uid==os.getuid() and stat.S_IMODE(info.st_mode)==0o700:return p/'cq-maintenance'
        except OSError:pass
    return Path(f'/tmp/cq-maintenance-{os.getuid()}')

@contextlib.contextmanager
def lock(name):
    root=runtime_dir();root.mkdir(parents=True,exist_ok=True,mode=0o700)
    info=root.lstat()
    if not stat.S_ISDIR(info.st_mode) or info.st_uid!=os.getuid() or stat.S_IMODE(info.st_mode)!=0o700:raise Problem('Unsafe runtime directory')
    fd=os.open(root/(name+'.lock'),os.O_CREAT|os.O_RDWR|os.O_NOFOLLOW,0o600)
    try:
        try:fcntl.flock(fd,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:raise Problem(name+' is already running')
        yield
    finally:os.close(fd)

def run(argv, *, timeout=30, env=None, foreground=False, input=None):
    argv=[str(a) for a in argv]
    environment=dict(os.environ)
    environment['PATH']=str(Path.home()/'.local/bin')+os.pathsep+environment.get('PATH','/usr/bin:/bin')
    if not foreground:
        environment.update(GIT_TERMINAL_PROMPT='0',GCM_INTERACTIVE='never',GIT_OPTIONAL_LOCKS='0',SSH_ASKPASS='/bin/false',GIT_SSH_COMMAND='ssh -oBatchMode=yes -oIdentityAgent=none -oConnectTimeout=10 -oNumberOfPasswordPrompts=0')
    if env:environment.update(env)
    try:
        if foreground:return subprocess.run(argv,env=environment,timeout=timeout)
        process=subprocess.Popen(argv,env=environment,text=True,stdin=subprocess.PIPE if input is not None else subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE,start_new_session=True)
        try:out,err=process.communicate(input=input,timeout=timeout)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid,signal.SIGTERM)
            try:process.communicate(timeout=2)
            except subprocess.TimeoutExpired:os.killpg(process.pid,signal.SIGKILL);process.communicate()
            raise Problem(Path(argv[0]).name+' timed out')
        except BaseException:
            with contextlib.suppress(ProcessLookupError):os.killpg(process.pid,signal.SIGKILL)
            process.communicate()
            raise
        return subprocess.CompletedProcess(argv,process.returncode,out,err)
    except OSError:raise Problem('Cannot run '+Path(argv[0]).name)
    except subprocess.TimeoutExpired:raise Problem(Path(argv[0]).name+' timed out')

def require(result):
    if result.returncode:raise Problem(Path(str(result.args[0])).name+f' failed (exit {result.returncode})')
    return result

def signal_bar(number=12):
    try:subprocess.run(['pkill','-u',str(os.getuid()),f'-RTMIN+{number}','-x','waybar'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=2)
    except (OSError,subprocess.TimeoutExpired):pass
