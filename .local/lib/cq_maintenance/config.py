from __future__ import annotations
import os, re, tomllib
from pathlib import Path
from .model import Settings

DEFAULTS = {
 'pass-sync': {'provider':'pass_sync','interval':300,'options':{'warning_seconds':604800,'error_seconds':1209600}},
 'taskwarrior': {'provider':'taskwarrior','interval':60,'options':{'stale_seconds':86400}},
 'dotfiles': {'provider':'git', 'options':{'profile':'dotfiles'}},
 'dotlocal': {'provider':'git', 'options':{'profile':'dotlocal'}},
 'crypt-sync': {'provider':'crypt'},
 'mail': {'provider':'mail', 'options':{'component':'mail','expected_timer':True,'stale_seconds':1200}},
 'contacts': {'provider':'mail', 'options':{'component':'contacts','expected_timer':True,'stale_seconds':1200}},
 'mail-setup': {'provider':'mail_setup', 'interval':300},
 'syncthing': {'provider':'syncthing', 'timeout':60},
 'arch': {'provider':'packages','interval':21600,'timeout':150,'options':{'kind':'arch','error_threshold':20}},
 'aur': {'provider':'packages','interval':21600,'timeout':120,'options':{'kind':'aur','error_threshold':0}},
 'flatpak': {'provider':'packages','enabled':False,'interval':21600,'timeout':120,'options':{'kind':'flatpak'}},
 'failed-units': {'provider':'units','options':{'ignore':[]}},
}

SETUP_DEFAULTS = {
 'taskwarrior': {'provider':'taskwarrior'},
 'maintenance': {'provider':'maintenance'},
 'mail': {'provider':'mail'},
 'paru': {'provider':'paru'},
 'gopass-jsonapi': {'provider':'browser','options':{'browsers':['firefox'],'gnupghome':'~/.config/gnupg','password_store':'~/Sync/Password-Store'}},
}

def xdg(kind):
    value=os.environ.get(f'XDG_{kind.upper()}_HOME','')
    return Path(value) if value and Path(value).is_absolute() else Path.home() / {'config':'.config','state':'.local/state','cache':'.cache'}[kind]

def config_path():
    explicit=os.environ.get('CQ_MAINTENANCE_CONFIG')
    if explicit: return Path(explicit).expanduser()
    base=Path(os.environ['CQ_CONFIG_DIR']).expanduser() if os.environ.get('CQ_CONFIG_DIR') else xdg('config')/'cq'
    return base/'maintenance/config.toml'

def merge(a,b):
    result=dict(a)
    for key,value in b.items():
        result[key]=merge(result[key],value) if isinstance(value,dict) and isinstance(result.get(key),dict) else value
    return result

def load():
    path=config_path()
    data={'checks':DEFAULTS,'setup':SETUP_DEFAULTS}
    for source in (path,path.with_name('config.local.toml')):
        if source.exists(): data=merge(data,tomllib.loads(source.read_text()))
    settings=Settings.model_validate(data)
    for name in list(settings.checks)+list(settings.setup):
        if not re.fullmatch('[a-z0-9][a-z0-9_.-]*',name): raise ValueError('Invalid check ID: '+name)
    return settings

def toggle(name, enabled):
    import tomli_w
    from .util import atomic_text
    settings=load()
    if name not in settings.checks: raise ValueError('Unknown check: '+name)
    path=config_path().with_name('config.local.toml')
    data=tomllib.loads(path.read_text()) if path.exists() else {}
    data=merge(data,{'checks':{name:{'enabled':enabled}}})
    atomic_text(path,tomli_w.dumps(data))


def toggle_setup(name, enabled):
    import tomli_w
    from .util import atomic_text
    if name not in load().setup:raise ValueError('Unknown setup item: '+name)
    path=config_path().with_name('config.local.toml')
    data=tomllib.loads(path.read_text()) if path.exists() else {}
    atomic_text(path,tomli_w.dumps(merge(data,{'setup':{name:{'enabled':enabled}}})))
