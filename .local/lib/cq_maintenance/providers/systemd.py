import fnmatch
from ..util import require,Problem
from .base import action

def check(ctx):
    units=[];details=[]
    for scope in ('user','system'):
        prefix=['systemctl']+(['--user'] if scope=='user' else [])
        result=require(ctx.run(prefix+['--failed','--no-legend','--plain','--no-pager']))
        for row in result.stdout.splitlines():
            fields=row.split()
            if not fields:continue
            name=fields[0]
            if any(fnmatch.fnmatch(name,pattern) for pattern in ctx.options.get('ignore',[])):continue
            units.append({'scope':scope,'unit':name});details.append(scope+': '+name)
    return ctx.result('error' if units else 'ok',f'{len(units)} failed units' if units else 'No failed units',metrics={'units':units},details=details,actions=[action('Review logs / restart a selected unit',False,'review')] if units else [])
def execute(ctx,id):raise Problem('Choose a specific unit in the dashboard; no blanket restart/reset-failed')
def open(ctx):return ['journalctl','--user','-p','err','-n','100','--no-pager']
