import json
from datetime import datetime
from ..model import now
from ..util import require,Problem
from .base import action

def check(ctx):
    if ctx.config.provider=='mail_setup':
        result=ctx.run(['cq_mailctl','setup','--check','--json'],timeout=45)
        try:data=json.loads(result.stdout)
        except ValueError:raise Problem('Mail setup check unavailable; update cq_mailctl')
        missing=data.get('missing_prerequisites',[]);drift=data.get('changed',[])
        return ctx.result('warning' if missing or drift else 'ok',f'{len(drift)} generated files need setup' if drift else 'Configuration current' if not missing else 'Prerequisites missing',details=missing+drift,metrics=data,actions=[action('Apply local mail setup')] if drift and not missing else [])
    component=ctx.options.get('component',ctx.id)
    data=json.loads(require(ctx.run(['cq_mailctl','status','--json'])).stdout).get(component,{})
    stamp=data.get('last_success')
    timestamp=datetime.fromisoformat(stamp).timestamp() if stamp else None
    age=now()-timestamp if timestamp else None
    record=data.get('state','unknown')
    state='error' if record=='error' else 'warning' if record=='unlock-required' else 'unknown' if age is None else 'warning' if age>ctx.options.get('stale_seconds',1200) else 'ok'
    details=[data.get('message','No sync recorded')]
    if ctx.options.get('expected_timer',True):
        result=ctx.run(['systemctl','--user','is-active',f'cq-{component}.timer'])
        if result.stdout.strip()!='active':state='warning';details.append('Expected timer is not active; enable explicitly with cq_mailctl timers-install.')
    summary=('Never synced' if age is None else f'Last success {int(max(age,0)//60)}m ago')+(' · unlock required' if record=='unlock-required' else '')
    return ctx.result(state,summary,details=details,last_success=timestamp,metrics={'component':component},activity='syncing' if record=='running' else '',actions=[action('Sync '+component)])
def execute(ctx,id):
    args=['cq_mailctl','setup'] if ctx.config.provider=='mail_setup' else ['cq_mailctl','contacts','sync'] if ctx.options.get('component',ctx.id)=='contacts' else ['cq_mailctl','sync']
    result=ctx.run(args,foreground=True,timeout=2100)
    if result.returncode==75:return 'Sync already running; existing operation left to finish'
    require(result);return 'Mail operation completed'
def open(ctx):return ['cq_mailctl','guide']
