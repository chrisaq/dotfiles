import json
from pathlib import Path
from ..util import require,Problem
from .base import action

def script(ctx):return Path(ctx.options.get('script','~/.local/bin/crypt-sync/crypt-sync.sh')).expanduser()
def environment(ctx):
    return {'PASSWORD_STORE_DIR':str(Path(ctx.options.get('store','~/Sync/Password-Store')).expanduser()),'XDG_BIN_HOME':str(Path(ctx.options.get('bin_home','~/.local/bin')).expanduser()),'GNUPGHOME':str(Path(ctx.options.get('gnupghome','~/.config/gnupg')).expanduser())}
def check(ctx):
    data=json.loads(require(ctx.run([script(ctx),'--check','--json'],env=environment(ctx))).stdout)
    rows=data['entries'];counts={state:sum(row['state']==state for row in rows) for state in ('ok','encrypt','decrypt','invalid','missing')}
    state='error' if counts['invalid'] else 'pending' if counts['encrypt'] or counts['decrypt'] else 'ok'
    summary=f'→vault {counts["encrypt"]} · →local {counts["decrypt"]}'
    details=[f'{row["name"]}: {row["state"]}' for row in rows if row['state'] not in ('ok','missing')]
    return ctx.result(state,summary,details=details,metrics={'counts':counts,'entries':rows},last_success=data.get('last_success'),actions=[action('Run crypt-sync (newest timestamp wins)')])
def execute(ctx,id):
    args=[script(ctx)]
    result=ctx.run(args,env=environment(ctx),foreground=True,timeout=600)
    if result.returncode:raise Problem('Crypt-sync failed; see the per-file output above')
    return 'Crypt-sync completed'
def open(ctx):return ['cq_maintenance','tui','--select',ctx.id]
