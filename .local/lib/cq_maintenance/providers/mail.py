"""Mail health from recorded outcomes; observation never tries credentials."""
import json,os
from datetime import datetime
from pathlib import Path
from ..model import now
from ..config import xdg
from ..util import require,Problem,read_json
from .base import action


def from_status(ctx,data,timer_active=None):
    component=ctx.options.get('component',ctx.id)
    stamp=data.get('last_success')
    timestamp=datetime.fromisoformat(stamp).timestamp() if stamp else None
    age=now()-timestamp if timestamp else None
    record=data.get('state','unknown')
    attempt=data.get('last_attempt')
    attempt_time=datetime.fromisoformat(attempt).timestamp() if attempt else None
    running=record=='running'
    stalled=running and attempt_time is not None and now()-attempt_time>ctx.options.get('running_timeout',2100)
    state='error' if record=='error' else 'warning' if stalled else 'pending' if record in ('unlock-required','running') else 'unknown' if age is None else 'warning' if age>ctx.options.get('stale_seconds',1200) else 'ok'
    details=[data.get('message','No sync recorded')]
    success='Never synced' if age is None else f'Last success {int(max(age,0)//60)}m ago'
    summary=('Sync may have stalled · ' if stalled else 'Syncing · ' if running else '')+success
    if record=='unlock-required':
        summary+=' · last attempt needed unlock'
        details.append('This is the last sync attempt, not a live key-lock test. After unlocking, use Sync or wait for the next timer attempt. Refresh only reads status.')
    if stalled:details.append('No progress recorded within the sync time limit; inspect the service before retrying.')
    if ctx.options.get('expected_timer',True) and timer_active is False:
        if state!='error':state='warning'
        details.append('Expected timer is not active; enable explicitly with cq_mailctl timers-install.')
    return ctx.result(state,summary,details=details,last_success=timestamp,metrics={'component':component,'timer_active':timer_active},activity='syncing' if running and not stalled else '',actions=[action('Sync '+component)])


def check(ctx):
    if ctx.config.provider=='mail_setup':
        result=ctx.run(['cq_mailctl','setup','--check','--json'],timeout=45)
        try:data=json.loads(result.stdout)
        except ValueError:raise Problem('Mail setup check unavailable; update cq_mailctl')
        missing=data.get('missing_prerequisites',[]);drift=data.get('changed',[])
        return ctx.result('warning' if missing or drift else 'ok',f'{len(drift)} generated files need setup' if drift else 'Configuration current' if not missing else 'Prerequisites missing',details=missing+drift,metrics=data,actions=[action('Apply local mail setup')] if drift and not missing else [])
    component=ctx.options.get('component',ctx.id)
    data=json.loads(require(ctx.run(['cq_mailctl','status','--json'])).stdout).get(component,{})
    timer_active=None
    if ctx.options.get('expected_timer',True):
        result=ctx.run(['systemctl','--user','is-active',f'cq-{component}.timer'])
        timer_active=result.stdout.strip()=='active'
    return from_status(ctx,data,timer_active)


def overlay(ctx,previous):
    """Cheap current progress for the bar/TUI, retaining the last timer observation."""
    if previous.metrics.get('component') is None:return previous
    try:
        settings_path=Path(os.environ.get('CQ_MAIL_CONFIG',str(Path.home()/'.config/mutt/settings.json'))).expanduser()
        settings=json.loads(settings_path.read_text())
        configured=settings.get('state') or os.environ.get('CQ_MAIL_STATE')
        root=Path(configured).expanduser().resolve() if configured else xdg('state')/'cq-mail'
        component=ctx.options.get('component',ctx.id)
        if component not in ('mail','contacts'):return previous
        data=read_json(root/(component+'-status.json'))
        if not isinstance(data,dict) or not data.get('last_attempt'):return previous
        row=from_status(ctx,data,previous.metrics.get('timer_active'))
        # Preserve collector freshness independently of the live progress file.
        row.checked_at=previous.checked_at
        return row
    except (OSError,ValueError,TypeError):
        return previous


def execute(ctx,id):
    args=['cq_mailctl','setup'] if ctx.config.provider=='mail_setup' else ['cq_mailctl','contacts','sync'] if ctx.options.get('component',ctx.id)=='contacts' else ['cq_mailctl','sync']
    result=ctx.run(args,foreground=True,timeout=2100)
    if result.returncode==75:return 'Sync deferred: sync already running or scheduled credentials need unlocking; inspect mail status'
    require(result)
    if ctx.config.provider=='mail':
        component=ctx.options.get('component',ctx.id)
        if component in ('mail','contacts'):
            unit='cq-'+component+'.service'
            failed=ctx.run(['systemctl','--user','is-failed',unit])
            if failed.stdout.strip()=='failed':
                cleared=ctx.run(['systemctl','--user','reset-failed',unit])
                if cleared.returncode:return 'Sync completed; corresponding timer failure flag could not be cleared'
    return 'Mail operation completed'


def open(ctx):return ['cq_mailctl','guide']
