from __future__ import annotations
import json,subprocess,sys
from pathlib import Path
import typer
from rich.console import Console
from rich.prompt import Prompt,Confirm
from rich.text import Text
from .config import load,config_path,DEFAULTS,toggle
from .model import Settings
from .util import Problem,run,require,atomic_text

from .guide import QUICKSTART

app=typer.Typer(context_settings={'help_option_names':['-h','--help']},epilog=QUICKSTART,invoke_without_command=True,no_args_is_help=False,add_completion=False,pretty_exceptions_enable=False,help='Inspect and maintain sync, configuration, services and updates. New machine? Start with cq_maintenance guide.')
config_app=typer.Typer(help='Shared defaults and machine-local overrides.');app.add_typer(config_app,name='config')
console=Console()

@app.callback()
def main(ctx:typer.Context):
    if ctx.invoked_subcommand is None:
        from .dashboard import MaintenanceApp
        if not sys.stdin.isatty() or not sys.stdout.isatty():
            guide()
            return
        MaintenanceApp(startup_guide=True).run()


@app.command('guide')
def guide():
    """First-time machine setup: prerequisites, monitoring, service setup and first sync."""
    from rich.markdown import Markdown
    from .guide import GUIDE
    console.print(Markdown(GUIDE))

app.command('help',hidden=True)(guide)
app.command('h',hidden=True)(guide)

def output_results(rows,json_output):
    if json_output:print(json.dumps([row.model_dump() for row in rows],ensure_ascii=False))
    else:
        from .view import report
        report(rows)

@app.command()
def status(json_output:bool=typer.Option(False,'--json'),disabled:bool=False):
    """Read cached observations; does not run checks or contact servers."""
    from .engine import snapshot
    output_results(snapshot(include_disabled=disabled),json_output)

@app.command()
def check(id:str|None=typer.Argument(None),all_checks:bool=typer.Option(False,'--all'),due:bool=False,json_output:bool=typer.Option(False,'--json'),quiet:bool=False):
    """Refresh enabled checks; remote queries never open authentication prompts."""
    from .engine import collect
    if id and all_checks:raise typer.BadParameter('Choose an ID or --all, not both')
    rows=collect([id] if id else None,due=due)
    if not quiet:output_results(rows,json_output)

@app.command()
def fix(id:str|None=typer.Argument(None),all_checks:bool=typer.Option(False,'--all'),action:str='fix',dry_run:bool=False,yes:bool=typer.Option(False,'--yes','-y')):
    """Run guarded fixes. Upgrades/restarts need an explicit check and action."""
    from .engine import fix as repair
    if id and all_checks:raise typer.BadParameter('Choose an ID or --all, not both')
    if not id and not all_checks:raise typer.BadParameter('Choose a check ID or --all')
    if all_checks and action!='fix':raise typer.BadParameter('Reviewed actions require one explicit check')
    if not dry_run and not yes:
        console.print('Safe batch excludes upgrades, commits, publishing and blanket restarts.' if all_checks else Text(f'Action {action} for {id}; current conditions will be rechecked.'))
        if not Confirm.ask('Continue?',default=False):raise typer.Exit()
    rows=repair([id] if id else None,action_id=action,dry_run=dry_run)
    for row in rows:console.print(Text(f'{row["id"]}: {row["state"]} · {row["message"]}'+(' · remaining '+row['remaining'] if row.get('remaining') else '')))
    if any(row['state']=='blocked' for row in rows):raise typer.Exit(1)

@app.command('open')
def open_check(id:str):
    """Open the existing workbench, guide or service UI."""
    from .providers import get
    from .providers.base import Context
    from .engine import previous
    settings=load()
    if id not in settings.checks:raise typer.BadParameter('Unknown check')
    ctx=Context(id,settings.checks[id],previous(id))
    require(run(get(ctx.config.provider).open(ctx),foreground=True,timeout=86400))

@app.command('restart-unit')
def restart_selected_unit(id:str,unit:str,scope:str=typer.Option('user','--scope'),yes:bool=typer.Option(False,'--yes','-y')):
    """Restart one still-failed unit after explicit review; never restart all units."""
    from .providers.base import Context
    from .providers.systemd import restart_unit,validate_unit
    from .engine import collect,log_event
    settings=load()
    if id not in settings.checks or settings.checks[id].provider!='units' or not settings.checks[id].enabled:
        raise typer.BadParameter('Choose an enabled failed-unit check')
    row={'scope':scope,'unit':unit};validate_unit(row)
    if not yes and not Confirm.ask(f'Restart {scope}: {unit}?',default=False):return
    try:
        message=restart_unit(Context(id,settings.checks[id],checking=False),row)
        log_event({'id':id,'state':'completed','message':message});console.print(Text(message))
    finally:collect([id])

@app.command()
def review(id:str):
    """Review a crypt-sync source, one failed unit or an explicit upgrade."""
    from .providers.base import Context
    from .engine import check_one,collect,log_event
    settings=load()
    if id not in settings.checks:raise typer.BadParameter('Unknown check')
    config=settings.checks[id];ctx=Context(id,config,checking=False)
    result=check_one(id,config)
    if config.provider=='crypt':
        from .providers.crypt import script,environment
        rows=[r for r in result.metrics.get('entries',[]) if r['state'] in ('conflict','unverified','invalid')]
        if not rows:console.print('No ambiguous entries. Use guarded sync to verify or transfer.');return
        for number,row in enumerate(rows,1):console.print(Text(f'{number}. {row["name"]} · {row["state"]}'))
        choice=Prompt.ask('Entry (q to cancel)',default='q')
        if choice=='q':return
        if not choice.isdigit() or not 1<=int(choice)<=len(rows):raise typer.BadParameter('Invalid entry')
        row=rows[int(choice)-1]
        console.print(Text('Local: '+row['local']+'\nVault: '+row['vault']))
        preference=Prompt.ask('Authoritative source',choices=['local','vault','cancel'],default='cancel')
        if preference=='cancel':return
        if Confirm.ask('Replace the other copy with this source?',default=False):
            require(run([script(ctx),'--resolve',row['name'],'--prefer',preference],env=environment(ctx),foreground=True,timeout=300))
            log_event({'id':id,'state':'completed','message':'Reviewed source selection for '+row['name']})
    elif config.provider=='units':
        rows=result.metrics.get('units',[])
        if not rows:console.print('No failed units.');return
        for number,row in enumerate(rows,1):console.print(Text(f'{number}. {row["scope"]}: {row["unit"]}'))
        choice=Prompt.ask('Unit (q to cancel)',default='q')
        if choice=='q':return
        if not choice.isdigit() or not 1<=int(choice)<=len(rows):raise typer.BadParameter('Invalid unit')
        row=rows[int(choice)-1]
        operation=Prompt.ask('Action',choices=['logs','restart','cancel'],default='logs')
        if operation=='cancel':return
        prefix=['--user'] if row['scope']=='user' else []
        if operation=='logs':
            require(run(['journalctl',*prefix,'-u',row['unit'],'-n','100','--no-pager'],foreground=True));Prompt.ask('Press Enter to return',default='')
        elif Confirm.ask('Restart this specific unit?',default=False):
            from .providers.systemd import restart_unit
            message=restart_unit(ctx,row)
            log_event({'id':id,'state':'completed','message':message})
    else:
        choices=[a for a in result.actions if not a.safe and a.id!='open']
        if not choices:open_check(id);return
        for number,a in enumerate(choices,1):console.print(Text(f'{number}. {a.label}'))
        choice=Prompt.ask('Action (q to cancel)',default='q')
        if choice=='q':return
        if not choice.isdigit() or not 1<=int(choice)<=len(choices):raise typer.BadParameter('Invalid action')
        selected=choices[int(choice)-1]
        fix(id=id,all_checks=False,action=selected.id,dry_run=False,yes=False)
    collect([id])

@app.command()
def tui(select:str|None=typer.Option(None,'--select'),view:str=typer.Option('health','--view')):
    """Open the live Textual dashboard; repairs require explicit actions."""
    from .dashboard import MaintenanceApp
    if view not in ('health','setup'):raise typer.BadParameter('View must be health or setup')
    MaintenanceApp(select=select,view=view).run()

@app.command()
def waybar():
    """Emit cached status as one Waybar JSON line."""
    from .view import waybar as render
    render()

@app.command()
def notify():
    """Refresh Waybar from cached/local status; no checks, authentication or repairs."""
    from .engine import notify_bar
    notify_bar()

@app.command()
def menu():
    """Dynamic Rofi action menu for enabled checks; no repairs on opening."""
    from .engine import snapshot
    settings=load();rows=snapshot(settings)
    choices=[('Dashboard',['tui']),('Machine setup',['tui','--view','setup']),('Refresh all checks',['check','--all']),('Fix / sync all safely',['fix','--all'])]
    for row in rows:
        if row.id=='monitor':continue
        if row.id.startswith('setup:'):
            choices.append((row.id+' · setup',['tui','--view','setup','--select',row.id.split(':',1)[1]]));continue
        choices.extend([(row.id+' · details',['tui','--select',row.id]),(row.id+' · refresh',['check',row.id])])
        for a in row.actions:
            args=['open',row.id] if a.id=='open' else ['review',row.id] if not a.safe else ['fix',row.id]
            choices.append((row.id+' · '+a.label,args))
    response=run(settings.menu,timeout=120,input='\n'.join(label for label,_ in choices))
    if response.returncode:return
    label=response.stdout.strip();selected=next((args for name,args in choices if name==label),None)
    if selected:
        # Pass an argv array; neither labels nor provider output are shell code.
        subprocess.Popen(settings.terminal+[str(Path.home()/'.local/bin/cq_maintenance'),*selected],start_new_session=True)

@app.command()
def setup():
    """Install/enable only the monitoring timer. Never repairs other services."""
    load()
    from .provision.units import directory as unit_directory,expected
    directory=unit_directory();directory.mkdir(parents=True,exist_ok=True)
    files={path.name:content for path,content in expected().items()}
    for name,content in files.items():
        path=directory/name
        if path.is_symlink() or path.exists() and not path.read_text().startswith('# Managed by cq_maintenance setup.\n'):raise Problem('Refusing to replace an unrelated '+name)
    for name,content in files.items():atomic_text(directory/name,content)
    require(run(['systemctl','--user','daemon-reload']))
    require(run(['systemctl','--user','enable','--now','cq-maintenance.timer']))
    console.print('Monitoring enabled. Existing sync schedules are unchanged.')

@app.command('setup-status')
def setup_status(id:str|None=typer.Argument(None),json_output:bool=typer.Option(False,'--json')):
    """Inspect machine setup now; no packages, credentials or configuration are changed."""
    from .provision.core import inspect_one,inspect_all
    rows=[inspect_one(id,save=True)] if id else inspect_all(save=True)
    if json_output:print(json.dumps([r.model_dump() for r in rows]))
    else:
        for row in rows:
            console.print(Text(f'{row.id}: {row.status} · {row.summary}'))
            for detail in row.details:console.print(Text('  '+detail))

@app.command('setup-plan')
def setup_plan(id:str,action:str='apply',json_output:bool=typer.Option(False,'--json')):
    """Inspect and preview a setup dependency plan without applying it."""
    from .provision.core import plan
    result=plan(id,action)
    if json_output:print(result.model_dump_json(indent=2))
    else:show_setup_plan(result)

def show_setup_plan(result):
    console.print(Text('Setup '+result.id+' · '+result.action))
    for reason in result.blockers:console.print(Text('BLOCKED: '+reason,style='red'))
    for n,step in enumerate(result.steps,1):
        console.print(Text(f'{n}. {step.title}'))
        if step.options.get('packages'):console.print(Text('   '+', '.join(step.options['packages'])))
    for change in result.changes:console.print(Text('  '+change))
    if not result.steps and not result.blockers:console.print('Already ready; no changes required.')

@app.command('setup-apply')
def setup_apply(id:str,action:str='apply',dry_run:bool=False,yes:bool=typer.Option(False,'--yes','-y'),expected_plan:str|None=typer.Option(None,'--expected-plan',hidden=True)):
    """Apply one reviewed setup dependency plan; AUR and sudo prompts remain interactive."""
    from .provision.core import plan,apply
    result=plan(id,action)
    import hashlib
    if expected_plan and hashlib.sha256(result.model_dump_json().encode()).hexdigest()!=expected_plan:raise Problem('Setup plan changed since preview; inspect it again.')
    show_setup_plan(result)
    if dry_run:return
    if result.blockers:raise Problem('Resolve the listed blockers, then re-plan.')
    if not result.steps:return
    if not yes and not Confirm.ask('Apply this setup dependency plan?',default=False):return
    outcome=apply(result,lambda text:Confirm.ask(text,default=False),lambda text:console.print(Text(text)))
    console.print(Text(outcome.id+': '+outcome.status))

@config_app.command('example')
def config_example():
    import tomli_w
    from .config import SETUP_DEFAULTS
    print(tomli_w.dumps(Settings(checks=DEFAULTS,setup=SETUP_DEFAULTS).model_dump()))

@config_app.command('show')
def config_show():
    import tomli_w
    print(tomli_w.dumps(load().model_dump()))

@config_app.command('validate')
def config_validate():
    from .providers import get
    settings=load()
    for config in settings.checks.values():get(config.provider)
    from .provision.recipes import PROVIDERS
    if any(item.provider not in PROVIDERS for item in settings.setup.values()):raise Problem('Unknown setup provider')
    console.print('Valid configuration: '+str(config_path()))

@config_app.command('enable')
def config_enable(id:str):toggle(id,True)
@config_app.command('disable')
def config_disable(id:str):toggle(id,False)
