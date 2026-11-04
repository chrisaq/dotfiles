import json,re,tomllib
from pathlib import Path
from ..model import now
from ..util import Problem,require
from .base import action

def repository(ctx):
    if ctx.options.get('git_dir'):
        return Path(ctx.options['git_dir']).expanduser(),Path(ctx.options.get('work_tree','~')).expanduser()
    data=tomllib.loads(require(ctx.run(['cq_dotfiles-tui','config','show'])).stdout)
    profile=ctx.options.get('profile',ctx.id)
    return Path(data['repositories'][profile]['git_dir']).expanduser(),Path(data.get('home','~')).expanduser()

def inspect(ctx, refresh=True):
    directory,home=repository(ctx)
    prefix=['git','-C',str(home),'--git-dir='+str(directory),'--work-tree='+str(home)]
    def git(*args):return ctx.run(prefix+list(args))
    require(git('rev-parse','--git-dir'))
    rows=require(git('status','--porcelain=v1','-z','--untracked-files=no')).stdout.split('\0')
    # Rename records have a second path; count only status-prefixed records.
    statuses=[];i=0
    while i<len(rows):
        row=rows[i]
        if row:
            statuses.append(row[:2])
            if row[0] in 'RC' or row[1] in 'RC':i+=1
        i+=1
    metrics={'dirty':len(statuses),'staged':sum(s[0]!=' ' for s in statuses),'unstaged':sum(s[1]!=' ' for s in statuses),'conflicts':sum(s in ('DD','AU','UD','UA','DU','AA','UU') for s in statuses),'git_dir':str(directory)}
    details=[];remote_unknown=False
    branch=git('symbolic-ref','--short','HEAD')
    if branch.returncode:return ctx.result('warning','Detached HEAD; review repository',metrics=metrics,actions=[action('Open workbench',False,'open')]),prefix,None
    metrics['branch']=branch.stdout.strip()
    upstream=git('rev-parse','--symbolic-full-name','@{upstream}')
    remote=git('config','--get',f'branch.{metrics["branch"]}.remote').stdout.strip()
    rules=git('config','--get-all',f'remote.{remote}.fetch').stdout.splitlines() if remote else []
    valid=bool(remote and re.fullmatch(r'[A-Za-z0-9_.-]+',remote) and remote!='.' and rules)
    valid=valid and all(rule.startswith('^refs/heads/') or bool(re.fullmatch(r'\+?refs/heads/[^:]+:refs/remotes/'+re.escape(remote)+r'/[^:]+',rule)) for rule in rules)
    if upstream.returncode or not valid or not upstream.stdout.strip().startswith('refs/remotes/'+remote+'/'):
        remote_unknown=True;details.append('Missing or unsafe upstream/fetch configuration; repair in the dotfiles workbench.')
    else:
        previous=ctx.previous.metrics if ctx.previous else {}
        stamp=previous.get('remote_checked_at',0)
        attempt=previous.get('remote_attempt_at',0)
        if refresh and (ctx.force or now()-attempt>=ctx.options.get('remote_interval',900)):
            attempt=now()
            try:
                result=git('fetch','--no-tags','--prune','--no-prune-tags',remote)
            except Problem:
                result=type('Unavailable',(),{'returncode':1})()
            if result.returncode:
                remote_unknown=True;details.append('Remote refresh failed; authentication/network unavailable (no prompts).')
            else:stamp=now()
        metrics['remote_checked_at']=stamp
        metrics['remote_attempt_at']=attempt
        if attempt>stamp:
            remote_unknown=True
            details.append('Last remote refresh did not succeed; retry is rate-limited.')
        if not stamp:remote_unknown=True;details.append('Remote has not been checked by this monitor yet.')
        elif now()-stamp>ctx.options.get('remote_stale',2700):remote_unknown=True;details.append('Remote metadata is stale.')
        count=git('rev-list','--left-right','--count','HEAD...'+upstream.stdout.strip())
        if count.returncode:remote_unknown=True;details.append('Cannot compare with upstream.')
        else:metrics['ahead'],metrics['behind']=map(int,count.stdout.split())
    in_progress=any((directory/name).exists() for name in ('MERGE_HEAD','CHERRY_PICK_HEAD','REVERT_HEAD','rebase-merge','rebase-apply'))
    metrics['in_progress']=in_progress
    ahead=metrics.get('ahead',0);behind=metrics.get('behind',0)
    summary=f'{len(statuses)} changed · ↑{ahead} ↓{behind}'
    state='ok'
    if metrics['conflicts'] or in_progress or (ahead and behind):state='error';details.append('Conflict, divergence or Git operation requires manual review.')
    elif remote_unknown:state='unknown';summary+=' · remote unknown'
    elif statuses or ahead or behind:state='pending'
    actions=[action('Open workbench',False,'open')]
    if state!='error' and not remote_unknown and behind and not ahead and not statuses:actions.insert(0,action('Fast-forward clean repository'))
    return ctx.result(state,summary,metrics=metrics,details=details,actions=actions),prefix,upstream.stdout.strip()

def check(ctx):return inspect(ctx)[0]
def execute(ctx,id):
    result,prefix,upstream=inspect(ctx)
    if not any(a.id=='fix' and a.safe for a in result.actions):raise Problem('Repository needs review or has no safe fast-forward')
    require(ctx.run(prefix+['merge','--ff-only',upstream],timeout=120))
    return 'Fast-forwarded; restart/recheck if tool source changed'
def open(ctx):return ['cq_dotfiles-tui','--repo',ctx.options.get('profile',ctx.id)]
