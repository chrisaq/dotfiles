import json
from ..model import Result
from ..util import Problem,require
from .base import action

def argv(ctx,key):
    value=ctx.options.get(key)
    if not isinstance(value,list) or not value or not all(isinstance(a,str) and '\0' not in a for a in value):raise Problem('Configure '+key+' as a nonempty argv array')
    return value

def check(ctx):
    data=json.loads(require(ctx.run(argv(ctx,'check'))).stdout)
    # External output cannot inject actions or commands; those come only from config.
    result=Result(id=ctx.id,state=data['state'],summary=data['summary'],details=data.get('details',[]),metrics=data.get('metrics',{}))
    if ctx.options.get('fix'):result.actions=[action('Run configured repair',bool(ctx.options.get('safe_fix',False)))]
    return result

def execute(ctx,id):
    require(ctx.run(argv(ctx,'fix'),foreground=True));return 'Configured repair completed'
def open(ctx):return argv(ctx,'open')
