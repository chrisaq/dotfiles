import shutil
from ..util import require,Problem
from .base import action

def helper():return 'paru' if shutil.which('paru') else 'yay' if shutil.which('yay') else None

def check(ctx):
    kind=ctx.options.get('kind','arch')
    env={};args=[]
    if kind=='arch':
        root=ctx.cache('pacman');root.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
        env={'CHECKUPDATES_DB':str(root)};args=['checkupdates','--nocolor']
    elif kind=='aur':
        tool=helper()
        if not tool:raise Problem('No supported AUR helper (paru/yay)')
        args=[tool,'-Qua','--color','never']
    elif kind=='flatpak':args=['flatpak','remote-ls','--updates','--columns=application,branch','--system'] if ctx.options.get('installation')=='system' else ['flatpak','remote-ls','--updates','--columns=application,branch']
    else:raise Problem('Unsupported package provider')
    result=ctx.run(args,env=env)
    if result.returncode not in ((0,2) if kind=='arch' else (0,)):
        raise Problem(kind+' update query failed; metadata may be unavailable')
    lines=[row.strip() for row in result.stdout.splitlines() if row.strip()]
    return ctx.result('pending' if lines else 'ok',f'{len(lines)} updates available' if lines else 'Up to date',details=lines[:100],metrics={'updates':len(lines),'kind':kind},actions=[action('Review and upgrade packages',False,'upgrade')] if lines else [])
def execute(ctx,id):
    if id!='upgrade':raise Problem('Upgrades are separate from safe Fix all')
    kind=ctx.options.get('kind','arch')
    argv=['flatpak','update'] if kind=='flatpak' else [helper(),'-Syu'] if helper() else ['sudo','pacman','-Syu']
    require(ctx.run(argv,foreground=True,timeout=3600));return 'Upgrade command completed'
def open(ctx):return ['cq_maintenance','tui','--select',ctx.id]
