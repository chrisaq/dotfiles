"""Provider registry: implement check(), and optionally plan(), execute(), open()."""
from importlib import import_module
PROVIDERS={'taskwarrior':'taskwarrior','git':'git','crypt':'crypt','mail':'mail','mail_setup':'mail','syncthing':'syncthing','packages':'packages','units':'systemd','command':'command'}
def get(name):
    if name not in PROVIDERS:raise ValueError('Unknown provider: '+name)
    return import_module('.'+PROVIDERS[name],__name__)
