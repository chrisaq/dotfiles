import fnmatch,hashlib,re
from ..util import require,Problem,lock
from .base import action

def failed_units(ctx):
    units=[]
    for scope in ('user','system'):
        prefix=['systemctl']+(['--user'] if scope=='user' else [])
        result=require(ctx.run(prefix+['--failed','--no-legend','--plain','--no-pager']))
        for row in result.stdout.splitlines():
            fields=row.split()
            if not fields:continue
            name=fields[0]
            if any(fnmatch.fnmatch(name,pattern) for pattern in ctx.options.get('ignore',[])):continue
            units.append({'scope':scope,'unit':name})
    return units

def check(ctx):
    units=failed_units(ctx);details=[r['scope']+': '+r['unit'] for r in units]
    return ctx.result('error' if units else 'ok',f'{len(units)} failed units' if units else 'No failed units',metrics={'units':units},details=details,actions=[action('Review logs / restart a selected unit',False,'review')] if units else [])
def execute(ctx,id):raise Problem('Choose a specific unit in the dashboard; no blanket restart/reset-failed')
def open(ctx):return ['journalctl','--user','-p','err','-n','100','--no-pager']


def validate_unit(row):
    if row.get('scope') not in ('user','system') or not re.fullmatch(r'[A-Za-z0-9_.@:\\-]+\.(service|socket|timer|mount|automount|path|target|scope|slice|swap)',row.get('unit','')) or row['unit'].startswith('-'):
        raise Problem('Invalid unit selection')

def unit_logs(ctx,row):
    validate_unit(row)
    prefix=['--user'] if row['scope']=='user' else []
    result=ctx.run(['journalctl',*prefix,'-u',row['unit'],'-n','100','--no-pager','--output=short-iso'],timeout=30)
    if result.returncode:raise Problem('Cannot read this journal; check journal permissions.')
    return result.stdout or 'No accessible journal entries for this unit.'

def restart_unit(ctx,row):
    validate_unit(row)
    with lock('unit-'+hashlib.sha256((row['scope']+':'+row['unit']).encode()).hexdigest()):
        if row not in failed_units(ctx):raise Problem('This unit is no longer failed. Refresh before choosing another action.')
        args=['systemctl']+(['--user'] if row['scope']=='user' else [])+['restart',row['unit']]
        if row['scope']=='system':args=['sudo',*args]
        require(ctx.run(args,foreground=row['scope']=='system',timeout=120))
    return 'Restart completed for '+row['scope']+': '+row['unit']
