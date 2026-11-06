import json
from pathlib import Path
from ..util import require,Problem
from .base import action

def script(ctx):return Path(ctx.options.get('script','~/.local/bin/crypt-sync/crypt-sync.sh')).expanduser()
def environment(ctx):
    return {'PASSWORD_STORE_DIR':str(Path(ctx.options.get('store','~/Sync/Password-Store')).expanduser()),'XDG_BIN_HOME':str(Path(ctx.options.get('bin_home','~/.local/bin')).expanduser()),'GNUPGHOME':str(Path(ctx.options.get('gnupghome','~/.config/gnupg')).expanduser())}
def check(ctx):
    data=json.loads(require(ctx.run([script(ctx),'--check','--json'],env=environment(ctx))).stdout)
    rows=data['entries'];counts={state:sum(row['state']==state for row in rows) for state in ('ok','encrypt','decrypt','unverified','conflict','invalid','missing')}
    state='error' if counts['invalid'] else 'warning' if counts['conflict'] else 'pending' if counts['unverified'] or counts['encrypt'] or counts['decrypt'] else 'ok'
    summary=f'→vault {counts["encrypt"]} · →local {counts["decrypt"]} · review {counts["conflict"]+counts["unverified"]}'
    details=[f'{row["name"]}: {row["state"]}' for row in rows if row['state'] not in ('ok','missing')]
    if counts['unverified']:details.append('Verification pending on this machine: run cq_maintenance fix crypt-sync with GPG available. Equal timestamps alone do not establish a verified baseline.')
    return ctx.result(state,summary,details=details,metrics={'counts':counts,'entries':rows},last_success=data.get('last_success'),actions=[action('Guarded sync / verify unchanged copies'),action('Review a conflict',False,'resolve')])
def execute(ctx,id):
    args=[script(ctx),'--safe']
    result=ctx.run(args,env=environment(ctx),foreground=True,timeout=600)
    if result.returncode:raise Problem('Some crypt-sync entries remain blocked; see the per-file reasons above')
    return 'Guarded crypt-sync completed'
def open(ctx):return ['cq_maintenance','tui','--select',ctx.id]
