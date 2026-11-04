import shutil
from pathlib import Path
from ..util import require,Problem
from .base import action

def helper():return 'paru' if shutil.which('paru') else 'yay' if shutil.which('yay') else None

def local_revision(options):
    if options.get('kind','arch') not in ('arch','aur'):return None
    path=Path(options.get('database_path','/var/lib/pacman')).expanduser()/'local'
    try:
        info=path.stat()
        return [info.st_dev,info.st_ino,info.st_mtime_ns,info.st_ctime_ns]
    except OSError:return None

def invalidated(config,previous):
    """Cheap local stat only: normal pacman transactions invalidate Arch/AUR results."""
    if config.options.get('kind','arch') not in ('arch','aur'):return False
    database=Path(config.options.get('database_path','/var/lib/pacman')).expanduser()
    if (database/'db.lck').exists():return False
    revision=local_revision(config.options)
    return revision is not None and revision!=previous.metrics.get('local_revision')

def check(ctx):
    kind=ctx.options.get('kind','arch')
    revision=local_revision(ctx.options)
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
    # Paru's -Qu query returns 1 when nothing matches, not just on failure.
    # Only an empty, diagnostic-free AUR query can use that convention.
    # https://github.com/Morganamilo/paru/blob/v2.2.0/src/query.rs
    empty_aur=(kind=='aur' and result.returncode==1
               and not (result.stdout or '').strip() and not (result.stderr or '').strip())
    if not empty_aur and result.returncode not in ((0,2) if kind=='arch' else (0,)):
        raise Problem(kind+' update query failed; metadata may be unavailable')
    if revision!=local_revision(ctx.options):raise Problem('Installed packages changed during query; retry after the package transaction')
    lines=[row.strip() for row in result.stdout.splitlines() if row.strip()]
    return ctx.result('pending' if lines else 'ok',f'{len(lines)} updates available' if lines else 'Up to date',details=lines[:100],metrics={'updates':len(lines),'kind':kind,'local_revision':revision},actions=[action('Review and upgrade packages',False,'upgrade')] if lines else [])
def execute(ctx,id):
    if id!='upgrade':raise Problem('Upgrades are separate from safe Fix all')
    kind=ctx.options.get('kind','arch')
    argv=['flatpak','update'] if kind=='flatpak' else [helper(),'-Syu'] if helper() else ['sudo','pacman','-Syu']
    require(ctx.run(argv,foreground=True,timeout=3600));return 'Upgrade command completed'
def open(ctx):return ['cq_maintenance','tui','--select',ctx.id]
