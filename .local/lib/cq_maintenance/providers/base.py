from dataclasses import dataclass,field
import time
from pathlib import Path
from ..model import Result,Action,Check
from ..util import state_dir,cache_dir,run,require

@dataclass
class Context:
    id: str
    config: Check
    previous: Result | None = None
    force: bool = False
    checking: bool = True
    started: float = field(default_factory=time.monotonic)
    @property
    def options(self):return self.config.options
    def run(self,args,**kwargs):
        timeout=kwargs.pop('timeout',self.config.timeout)
        if self.checking and not kwargs.get('foreground'):
            remaining=self.config.timeout-(time.monotonic()-self.started)
            if remaining<=0:
                from ..util import Problem
                raise Problem('Check deadline exceeded')
            timeout=min(timeout,remaining)
        return run(args,timeout=timeout,**kwargs)
    def result(self,state,summary,**kwargs):return Result(id=self.id,state=state,summary=summary,**kwargs)
    def state(self,name):return state_dir()/'providers'/self.id/name
    def cache(self,name):return cache_dir()/self.id/name

def action(label='Sync',safe=True,id='fix',reason=''):return Action(id=id,label=label,safe=safe,reason=reason)
