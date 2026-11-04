from __future__ import annotations
import html,json
from .model import PRIORITY,now

ICONS={'ok':'󰄬','pending':'󰦖','warning':'󰀦','error':'󰅚','unknown':'󰋗','disabled':'󰘓'}
COLORS={'ok':'#a6da95','pending':'#eed49f','warning':'#f5a97f','error':'#ed8796','unknown':'#939ab7','disabled':'#6e738d'}
def age(stamp):
    if not stamp:return 'never'
    seconds=max(0,int(now()-stamp))
    return f'{seconds//3600}h ago' if seconds>=3600 else f'{seconds//60}m ago' if seconds>=60 else 'just now'

def payload(results):
    if not results:return {'text':ICONS['disabled'],'class':'disabled','alt':'disabled','tooltip':'Maintenance: no enabled checks'}
    results=sorted(results,key=lambda row:PRIORITY[row.state],reverse=True)
    worst=results[0].state;running=any(row.activity for row in results)
    count=sum(row.state!='ok' for row in results)
    text=ICONS[worst]+(f' {count}' if count else '')+(' 󰑐' if running else '')
    lines=['<b>Maintenance</b>']
    for row in results:
        line=f'{row.id}: {row.summary}'
        lines.append(f'<span foreground="{COLORS[row.state]}">{ICONS[row.state]} {html.escape(line)}</span>')
        lines.append('  '+html.escape(('stale · ' if row.stale else '')+'checked '+age(row.checked_at)+((' · '+row.activity) if row.activity else '')))
    lines.append('\nLeft: dashboard · Right: actions')
    return {'text':text,'alt':worst,'class':[worst]+(['running'] if running else []),'tooltip':'\n'.join(lines)}

def waybar():
    try:
        from .engine import snapshot
        data=payload(snapshot())
    except Exception:data={'text':ICONS['unknown'],'class':'unknown','alt':'unknown','tooltip':'Maintenance configuration/cache unavailable; open cq_maintenance to inspect.'}
    print(json.dumps(data,ensure_ascii=False))

def report(results):
    from rich.console import Console
    from rich.table import Table
    from rich.text import Text
    table=Table(title='Maintenance')
    for name in ('Check','State','Status','Checked'):table.add_column(name)
    for row in sorted(results,key=lambda r:PRIORITY[r.state],reverse=True):
        table.add_row(Text(row.id),Text(row.state,style=COLORS[row.state]),Text(row.summary+(' · '+row.activity if row.activity else '')),age(row.checked_at))
    Console().print(table)
