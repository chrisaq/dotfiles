from __future__ import annotations
from pathlib import Path
from rich.text import Text
from textual.app import App,ComposeResult
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
    DEFAULT_CSS='ConfirmAction {align:center middle;} ConfirmAction > Vertical {width:76; height:auto; max-height:80%; padding:1 2; background:$surface; border:round $warning;} ConfirmAction Horizontal {height:3; align:center middle;}'
    def __init__(self,title,body):super().__init__();self.title_text=title;self.body=body
    def compose(self):
        with Vertical():
            yield Label(self.title_text)
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
        self.register_theme(Theme(name='catppuccin-macchiato',primary='#8aadf4',secondary='#c6a0f6',accent='#c6a0f6',foreground='#cad3f5',background='#24273a',surface='#1e2030',panel='#363a4f',success='#a6da95',warning='#eed49f',error='#ed8796',dark=True))
    def compose(self)->ComposeResult:
        yield Header()
        yield Static('New machine? ? Startup guide · t Setup · r Refresh health',id='hint')
        with Horizontal(id='body'):
            yield DataTable(id='checks',cursor_type='row')
            with VerticalScroll(id='detail-pane'):
                yield Static(id='detail')
        with HorizontalScroll(id='buttons'):
            for id,label in [('refresh','Refresh'),('fix_all','Fix all'),('fix_selected','Fix selected'),('review','Review'),('open','Open'),('toggle','Toggle'),('setup','Setup'),('guide','Startup guide')]:yield Button(label,id=id)
        yield Footer()
    def check_action(self,action,parameters):
        if isinstance(self.screen,ModalScreen) and action in {'refresh','fix_all','fix_selected','review','open','toggle','quit','setup','guide'}:return False
        return True
    def on_resize(self,event):
        self.screen.set_class(event.size.width<110,'narrow')
    def on_mount(self):
        self.theme='catppuccin-'+load().theme
        self.query_one('#checks',DataTable).add_columns('Check','State','Status')
        self.repaint();self.set_interval(2,self.repaint)
        if self.initial_view=='setup':self.call_after_refresh(self.action_setup)
        elif self.startup_guide:
            from .provision.units import bootstrap_hint
            if bootstrap_hint(load()):self.call_after_refresh(self.action_guide)
    def repaint(self):
        table=self.query_one('#checks',DataTable);previous_selection=self.selected
        try:rows=snapshot(include_disabled=True)
        except Exception:
            self.query_one('#detail',Static).update('Configuration/cache unavailable. Run config validate.');return
        self.rows={row.id:row for row in rows}
        table.clear()
        for row in rows:table.add_row(row.id,Text(row.state,style=COLORS[row.state]),row.summary,key=row.id)
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
        lines=[row.id.upper(),row.state+' · '+row.summary,'Checked '+age(row.checked_at)]
        if row.last_success:lines.append('Last operation success '+age(row.last_success))
        if row.activity:lines.append('Activity: '+row.activity)
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
        try:
            with self.suspend():
                result=run([Path.home()/'.local/bin/cq_maintenance',*args],foreground=True,timeout=86400)
                if sys.stdin.isatty():input('\nPress Enter to return to the dashboard…')
            code=result.returncode
            if result.returncode:self.notify(f'Action failed (exit {result.returncode}); inspect its output or unit logs.',severity='error',timeout=10)
        except Exception as error:
            self.notify(str(error) if isinstance(error,Problem) else 'Could not run the terminal action. Use the CLI or inspect unit logs.',severity='error',timeout=10)
        self.repaint()
        return code
    def confirm(self,args,body):
        self.push_screen(ConfirmAction('Review maintenance action',body),lambda accepted:self.launch(args) if accepted else None)
    def action_fix_all(self):
        labels=[row.id+': '+a.label for row in self.rows.values() for a in row.actions if a.safe and a.id=='fix' and row.state!='disabled']
        self.confirm(['fix','--all','--yes'],'Recheck and run available safe actions:\n\n'+'\n'.join(labels)+'\n\nNo upgrades, commits, publishing, blanket restarts or ambiguous overwrites. GPG may need unlocking.')
    def action_fix_selected(self):
        if self.selected=='monitor' or (self.selected or '').startswith('setup:'):self.action_setup();return
        row=self.rows.get(self.selected)
        if row and row.state!='disabled' and any(a.safe and a.id=='fix' for a in row.actions):self.confirm(['fix',row.id,'--yes'],row.summary+'\n\nRecheck and perform the guarded fix?')
        else:self.notify('No safe fix available; use Review or Open.')
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
