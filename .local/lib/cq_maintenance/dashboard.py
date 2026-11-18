from __future__ import annotations
from pathlib import Path
from rich.text import Text
from textual.app import App,ComposeResult,SuspendNotSupported
from textual.theme import Theme
from textual.binding import Binding
from textual.containers import Horizontal,Vertical,VerticalScroll,HorizontalScroll
from textual.screen import ModalScreen
from textual.widgets import Header,Footer,DataTable,Static,Button,Label
from textual import work
from .config import load,toggle
from .engine import snapshot,collect
from .util import run,read_json,state_dir,Problem
from .view import COLORS,age

class ConfirmAction(ModalScreen[bool]):
    DEFAULT_CSS='ConfirmAction {align:center middle;} ConfirmAction > Vertical {width:90%; max-width:76; height:80%; max-height:24; padding:1 2; background:$surface; border:round $warning;} ConfirmAction #confirmation-body {height:1fr;} ConfirmAction Horizontal {height:3; align:center middle;}'
    def __init__(self,title,body):super().__init__();self.title_text=title;self.body=body
    def compose(self):
        with Vertical():
            yield Label(self.title_text)
            with VerticalScroll(id='confirmation-body'):
                yield Static(Text(self.body))
            with Horizontal():yield Button('Cancel',id='cancel');yield Button('Continue',id='yes',variant='warning')
    def on_button_pressed(self,event):
        event.stop()
        self.dismiss(event.button.id=='yes')
    def key_escape(self):self.dismiss(False)

class MaintenanceApp(App):
    TITLE='cq_maintenance'
    CSS='''#body {height:1fr;} #checks {width:48%;} #detail-pane {width:52%; height:1fr; padding:1 2;} #detail {height:auto;} .narrow #body {layout:vertical;} .narrow #checks {width:100%; height:14;} .narrow #detail-pane {width:100%; height:1fr;} #buttons {height:auto; dock:bottom;} #buttons Button {min-width:10; margin-right:1;} #hint {height:2; padding:0 1;}'''
    BINDINGS=[Binding('r','refresh','Refresh'),Binding('f','fix_all','Fix all'),Binding('s','fix_selected','Fix selected'),Binding('v','review','Review'),Binding('o','open','Open'),Binding('e','toggle','Enable/disable'),Binding('ctrl+t','theme','Theme'),Binding('q','quit','Quit'),Binding('t','setup','Setup'),Binding('question_mark','guide','Guide'),Binding('h','guide','Guide',show=False)]
    def __init__(self,select=None,view='health',startup_guide=False):
        super().__init__();self.startup_guide=startup_guide;self.selected=select;self.rows={};self.initial_view=view;self.setup_selection=select if view=='setup' else None
        self.action_status={}
        self.register_theme(Theme(name='catppuccin-macchiato',primary='#8aadf4',secondary='#c6a0f6',accent='#c6a0f6',foreground='#cad3f5',background='#24273a',surface='#1e2030',panel='#363a4f',success='#a6da95',warning='#eed49f',error='#ed8796',dark=True))
    def compose(self)->ComposeResult:
        yield Header()
        yield Static('e Enable/disable selected check · t Setup · ? Startup guide',id='hint')
        with Horizontal(id='body'):
            yield DataTable(id='checks',cursor_type='row')
            with VerticalScroll(id='detail-pane'):
                yield Static(id='detail')
        with HorizontalScroll(id='buttons'):
            for id,label in [('refresh','Refresh'),('fix_all','Fix all'),('fix_selected','Fix selected'),('review','Review'),('open','Open'),('toggle','Enable/disable (e)'),('setup','Setup'),('guide','Startup guide')]:yield Button(label,id=id)
        yield Footer()
    def check_action(self,action,parameters):
        if isinstance(self.screen,ModalScreen) and action in {'refresh','fix_all','fix_selected','review','open','toggle','quit','setup','guide'}:return False
        return True
    def on_resize(self,event):
        self.screen.set_class(event.size.width<110,'narrow')
    def on_mount(self):
        self.theme='catppuccin-'+load().theme
        self.query_one('#checks',DataTable).add_columns('Check','Enabled','State','Status')
        self.repaint();self.set_interval(2,self.repaint)
        if self.initial_view=='setup':self.call_after_refresh(self.action_setup)
        elif self.startup_guide:
            from .provision.units import bootstrap_hint
            if bootstrap_hint(load()):self.call_after_refresh(self.action_guide)
    def repaint(self):
        table=self.query_one('#checks',DataTable);previous_selection=self.selected
        try:
            settings=load()
            rows=snapshot(settings,include_disabled=True)
        except Exception:
            self.query_one('#detail',Static).update('Configuration/cache unavailable. Run config validate.');return
        self.rows={row.id:row for row in rows}
        table.clear()
        for row in rows:
            config=settings.setup.get(row.id.split(':',1)[1]) if row.id.startswith('setup:') else settings.checks.get(row.id)
            enabled=Text('Yes' if config.enabled else 'No',style=COLORS['ok' if config.enabled else 'disabled']) if config else Text('Auto' if row.id=='monitor' else '—',style=COLORS['disabled'])
            table.add_row(row.id,enabled,Text(row.state,style=COLORS[row.state]),row.summary,key=row.id)
        if previous_selection in self.rows:
            index=list(self.rows).index(previous_selection);table.move_cursor(row=index)
        elif rows:self.selected=rows[0].id
        self.show_detail()
    def on_data_table_row_highlighted(self,event):
        self.selected=str(event.row_key.value);self.show_detail()
    def show_detail(self):
        row=self.rows.get(self.selected)
        if not row:return
        events=[event for event in read_json(state_dir()/'actions.json',[]) if event.get('id')==row.id][-5:]
        settings=load()
        config=settings.setup.get(row.id.split(':',1)[1]) if row.id.startswith('setup:') else settings.checks.get(row.id)
        button=self.query_one('#toggle',Button)
        button.disabled=config is None
        button.label=('Disable (e)' if config.enabled else 'Enable (e)') if config else 'Enable/disable (e)'
        enabled=('Yes · e to disable' if config.enabled else 'No · e to enable') if config else 'Automatic'
        lines=[row.id.upper(),'Enabled on this machine: '+enabled,row.state+' · '+row.summary,'Checked '+age(row.checked_at)]
        if row.last_success:lines.append('Last operation success '+age(row.last_success))
        if row.activity:lines.append('Activity: '+row.activity)
        if row.id in self.action_status:lines+=['','Last requested action:',self.action_status[row.id]]
        detail_lines=[line.replace(str(Path.home())+'/', '~/') for line in row.details]
        lines+=['']+detail_lines+['','Available actions:']+[a.label+(' [safe batch]' if a.safe else ' [review]') for a in row.actions]
        if events:lines+=['','Recent actions:']+[event['state']+': '+event['message'] for event in events]
        self.query_one('#detail',Static).update(Text('\n'.join(lines)))
    def on_button_pressed(self,event):
        if event.button.id in {'refresh','fix_all','fix_selected','review','open','toggle','setup','guide'}:
            event.stop()
            getattr(self,'action_'+event.button.id)()
    @work(thread=True,exclusive=True,group='checks')
    def action_refresh(self):
        try:collect();self.call_from_thread(self.repaint)
        except Exception as error:self.call_from_thread(self.notify,str(error),severity='error')
    def launch(self,args):
        import sys
        code=None
        selected=args[1] if len(args)>1 and args[0] in {'fix','review','open'} and not args[1].startswith('-') else self.selected
        command='cq_maintenance '+' '.join(args)
        message='Running '+command+'; follow the output and prompts in the terminal.'
        if selected:self.action_status[selected]=message
        self.show_detail()
        try:
            with self.suspend():
                # Always leave suspend normally: terminal restoration must also
                # happen when process startup, execution or input fails.
                print('\nRunning '+command+'\n',flush=True)
                try:
                    result=run([Path.home()/'.local/bin/cq_maintenance',*args],foreground=True,timeout=86400)
                    code=result.returncode
                    message=(f'Completed: {command} (exit 0). See Recent actions below for the result.' if code==0
                             else f'Failed: {command} (exit {code}). Inspect the terminal output and Recent actions below.')
                except KeyboardInterrupt:
                    code=130;message='Interrupted: '+command+'. Check current status before retrying.'
                except Exception as error:
                    message='Failed: '+command+'. '+(str(error) if isinstance(error,Problem) else type(error).__name__+' while running the terminal action.')
                print('\n'+message,flush=True)
                if sys.stdin.isatty():
                    try:input('\nPress Enter to return to the dashboard…')
                    except (EOFError,KeyboardInterrupt):pass
        except SuspendNotSupported:
            message='Could not open the interactive terminal. Run '+command+' in a terminal to see output and password prompts.'
        except Exception as error:
            message='Could not run '+command+': '+(str(error) if isinstance(error,Problem) else type(error).__name__+'. Use the CLI or inspect unit logs.')
        if selected:self.action_status[selected]=message
        self.notify(message,severity='information' if code==0 else 'error',timeout=10)
        self.repaint()
        return code
    def confirm(self,args,body):
        selected=self.selected
        if selected:self.action_status[selected]='Awaiting confirmation: choose Continue to start, or Cancel to leave everything unchanged.'
        self.show_detail()
        def decided(accepted):
            if accepted:self.launch(args)
            else:
                if selected:self.action_status[selected]='Cancelled before starting; no maintenance command was run.'
                self.show_detail()
                self.notify('Action cancelled; nothing was run.')
        self.push_screen(ConfirmAction('Review maintenance action',body),decided)
    def action_fix_all(self):
        labels=[row.id+': '+a.label for row in self.rows.values() for a in row.actions if a.safe and a.id=='fix' and row.state!='disabled']
        self.confirm(['fix','--all','--yes'],'Recheck and run available safe actions:\n\n'+'\n'.join(labels)+'\n\nNo upgrades, commits, publishing, blanket restarts or ambiguous overwrites. GPG may need unlocking.')
    def action_fix_selected(self):
        if self.selected=='monitor' or (self.selected or '').startswith('setup:'):self.action_setup();return
        row=self.rows.get(self.selected)
        config=load().checks.get(self.selected)
        if row and row.state!='disabled' and config and config.enabled and config.provider=='pass_sync' and not any(a.safe and a.id=='fix' for a in row.actions):
            # An unchecked/failed cached observation may have no actions. This
            # provider's metadata-only check can recover its Fix action without
            # opening GPG or exporting anything. Execution still rechecks it.
            from .providers.base import Context
            from .providers.pass_sync import check
            try:
                row=check(Context(row.id,config))
                self.rows[row.id]=row
            except Exception as error:
                self.action_status[row.id]='No export started: '+(str(error) if isinstance(error,Problem) else 'could not check export status ('+type(error).__name__+').')
                self.show_detail()
                self.notify(self.action_status[row.id],severity='error',timeout=10)
                return
        if row and row.state!='disabled' and config and config.enabled and any(a.safe and a.id=='fix' for a in row.actions):
            body=row.summary+'\n\nRecheck and perform the guarded fix?'
            if config and config.provider=='pass_sync':
                from .providers.base import Context
                from .providers.pass_sync import paths
                store,database,base=paths(Context(row.id,config))
                body=('Export password store to KeePass?\n\nStore: '+str(store)+'\nTemplate: '+str(base)+'\nOutput: '+str(database)
                      +'\n\nChoose Continue to start. The dashboard will switch to the terminal to show export progress and any KeePass password or GPG unlock prompts. Press Enter after completion to return here.')
            self.confirm(['fix',row.id,'--yes'],body)
        else:
            if self.selected:self.action_status[self.selected]='No fix started: no safe fix is available. Refresh the checks or use Review or Open.'
            self.show_detail()
            self.notify('No safe fix available; refresh the checks or use Review or Open.')
    def action_review(self):
        if self.selected=='monitor' or (self.selected or '').startswith('setup:'):self.action_setup();return
        if self.selected and self.selected!='monitor' and self.rows[self.selected].state!='disabled':
            config=load().checks.get(self.selected)
            if config and config.provider=='units':
                from .unit_review import UnitReview
                self.push_screen(UnitReview(self.selected,config))
            else:self.launch(['review',self.selected])
    def action_open(self):
        if self.selected=='monitor' or (self.selected or '').startswith('setup:'):self.action_setup();return
        if self.selected and self.selected!='monitor':self.launch(['open',self.selected])
    def action_toggle(self):
        if (self.selected or '').startswith('setup:'):self.action_setup();return
        if self.selected and self.selected!='monitor':
            config=load().checks[self.selected];toggle(self.selected,not config.enabled);self.repaint()
    def action_theme(self):self.theme='catppuccin-latte' if self.theme=='catppuccin-macchiato' else 'catppuccin-macchiato'

    def action_setup(self):
        from .provision.ui import SetupScreen
        selected=self.setup_selection or ('maintenance' if self.selected=='monitor' else self.selected.split(':',1)[1] if (self.selected or '').startswith('setup:') else None)
        self.setup_selection=None
        self.push_screen(SetupScreen(selected))

    def action_guide(self):
        from .guide import StartupGuide
        self.push_screen(StartupGuide(),lambda open_setup:self.action_setup() if open_setup else None)
