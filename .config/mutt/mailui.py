"""NeoMutt's source-pipe pickers and message export helpers."""
from __future__ import annotations

from email import policy
from email.parser import BytesParser
from html import escape
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import uuid

from mailcore import ROOT, MailError, MailSystem, helper_path


class Terminal:
    """Separate streams work with non-seekable controlling terminals."""
    def __enter__(self):
        self.reader = open('/dev/tty', 'r')
        try:
            self.writer = open('/dev/tty', 'w')
        except OSError:
            self.reader.close()
            raise
        return self

    def __exit__(self, *args):
        self.reader.close()
        self.writer.close()

    def write(self, text):
        return self.writer.write(text)

    def flush(self):
        return self.writer.flush()

    def readline(self):
        return self.reader.readline()


def mutt_quote(value):
    return '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$').replace('`', '\\`') + '"'


def display_key(key):
    key = re.sub(r'\\[Cc]([a-zA-Z])', lambda m: 'Ctrl+' + m[1].upper(), key)
    key = key.replace('\\e', 'Esc ')
    key = key.replace('\\031', 'Ctrl+Y').replace('\\005', 'Ctrl+E')
    return key.replace('<Space>', ' Space').replace('<Return>', 'Enter').replace('<Tab>', 'Tab').strip()


def emit_push(action):
    print('push ' + mutt_quote(action))


def choose(rows, prompt):
    if not rows:
        return None
    command = ['fzf', '--no-multi', '--delimiter=\t', '--with-nth=2..',
               '--prompt=' + prompt, '--border', '--header=Enter: run · Esc: cancel']
    command += ['--tmux=center,85%,75%'] if os.environ.get('TMUX') else ['--height=80%']
    environment = dict(os.environ)
    # An inherited --expect or --print-query would change the picker protocol.
    environment.pop('FZF_DEFAULT_OPTS', None)
    environment.pop('FZF_DEFAULT_OPTS_FILE', None)
    try:
        with open('/dev/tty', 'w') as terminal:
            result = subprocess.run(command, input='\n'.join(rows), text=True,
                                    stdout=subprocess.PIPE, stderr=terminal, env=environment)
    except OSError as error:
        raise MailError('The picker needs fzf and an interactive terminal') from error
    if result.returncode in (1, 130):
        return None
    if result.returncode:
        raise MailError('fzf failed')
    try:
        index = int(result.stdout.split('\t', 1)[0])
    except ValueError as error:
        raise MailError('Invalid picker response') from error
    if not 0 <= index < len(rows):
        raise MailError('Invalid picker selection')
    return index


def palette(system, context):
    actions = json.loads((ROOT / 'actions.json').read_text())
    actions = [a for a in actions if context in a['contexts'] and a['key'] != '<F1>' and a['action'] != 'noop']
    rows = [f"{i}\t{display_key(a['key']):<12} {a['category']:<12} {a['description']}" for i, a in enumerate(actions)]
    selected = choose(rows, context + ' action > ')
    if selected is not None:
        action = actions[selected]
        command = '<' + action['action'] + '>' if action['kind'] == 'function' else action['action']
        command = command.replace('@MAILCTL@', str(helper_path()))
        command = command.replace('@DATABASE@', str(system.database))
        command = command.replace('@ATTACHMENTS@', system.settings['attachments'])
        emit_push(command)


def folders(system):
    candidates = []
    for path in [system.mail_root, *sorted(system.mail_root.iterdir())]:
        if not (path / 'cur').is_dir() or not (path / 'new').is_dir():
            continue
        # Macro token syntax must never come from a mailbox name.
        if any(ord(c) < 32 or c in '<>' for c in str(path)):
            continue
        name = 'Physical Inbox' if path == system.mail_root else path.name.lstrip('.')
        candidates.append((name, str(path)))
    rules = json.loads((ROOT / 'rules.json').read_text())
    views = [('Inbox', 'tag:inbox'), ('Unread Inbox', 'tag:inbox and tag:unread'),
             ('Flagged', 'tag:flagged'), ('All mail', '*')]
    views += [(r['tag'], 'tag:' + r['tag']) for r in rules]
    candidates = [(name + ' [view]', f'notmuch://{system.database}?query={query}') for name, query in views] + candidates
    selected = choose([f'{i}\t{name}' for i, (name, _) in enumerate(candidates)], 'folder > ')
    if selected is not None:
        emit_push('<change-folder><kill-line>' + candidates[selected][1] + '<enter>')


def read_message(data=None):
    return BytesParser(policy=policy.default).parsebytes(sys.stdin.buffer.read() if data is None else data)


def safe_filename(value):
    value = str(value).replace('\\', '/').rsplit('/', 1)[-1]
    value = ''.join(c for c in value if ord(c) >= 32 and c not in '\x7f')
    value = value.strip(' .')[:180]
    return value or 'attachment'


def save_unique(directory, name, data):
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    name = safe_filename(name)
    base = Path(name)
    for number in range(10000):
        path = directory / (name if not number else f'{base.stem}-{number}{base.suffix}')
        try:
            with path.open('xb') as stream:
                path.chmod(0o600)
                stream.write(data)
            return path
        except FileExistsError:
            continue
    raise MailError('Too many attachment filename collisions')


def attachments(system, message=None):
    message = message or read_message()
    saved = []
    for part in message.walk():
        if part.get_content_disposition() != 'attachment' and not part.get_filename():
            continue
        if part.get_content_type() == 'message/rfc822':
            data = b'\n'.join(p.as_bytes() for p in part.get_payload())
        elif part.is_multipart():
            continue
        else:
            data = part.get_payload(decode=True)
        if data is None:
            continue
        saved.append(save_unique(system.settings['attachments'], part.get_filename() or 'attachment', data))
    print(f'Saved {len(saved)} attachment(s) to {system.settings["attachments"]}', file=sys.stderr)
    return saved


class PlainHTML(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
        self.hidden = 0

    def handle_starttag(self, tag, attrs):
        if tag in ('script', 'style'):
            self.hidden += 1
        elif tag in ('br', 'p', 'div', 'li', 'tr') and not self.hidden:
            self.parts.append('\n')

    def handle_endtag(self, tag):
        if tag in ('script', 'style'):
            self.hidden = max(0, self.hidden - 1)

    def handle_data(self, data):
        if not self.hidden:
            self.parts.append(data)


def message_text(message):
    body = message.get_body(preferencelist=('plain', 'html'))
    if body is None:
        return ''
    text = body.get_content()
    if body.get_content_type() == 'text/html':
        parser = PlainHTML()
        parser.feed(text)
        text = ''.join(parser.parts)
    return text


def export_pdf(system, data=None, decoded=False):
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
    from datetime import datetime
    message = read_message(data)
    # NeoMutt's print pipe is decoded display text, not necessarily an RFC822 message.
    if (decoded or not message.keys()) and data is not None:
        text = data.decode('utf-8', errors='replace')
    else:
        text = '\n'.join(f'{h}: {message[h]}' for h in ('From', 'To', 'Date', 'Subject') if message[h]) + '\n\n' + message_text(message)
    if not text.strip():
        raise MailError('No printable message text')
    font = next((path for path in (Path('/usr/share/fonts/TTF/DejaVuSans.ttf'),
                                   Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'),
                                   Path('/usr/share/fonts/dejavu/DejaVuSans.ttf')) if path.is_file()), None)
    if font is None:
        raise MailError('Install ttf-dejavu for Unicode PDF export')
    pdfmetrics.registerFont(TTFont('MailUnicode', str(font)))
    styles = getSampleStyleSheet()
    style = styles['Normal']
    style.fontName = 'MailUnicode'
    style.fontSize = 9
    style.leading = 12
    directory = Path(system.settings['attachments']) / 'Emails'
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    path = directory / (datetime.now().strftime('%Y-%m-%d_%H%M%S_') + uuid.uuid4().hex[:8] + '.pdf')
    story = [Paragraph(escape(line) if line.strip() else '&#160;', style) for line in text.splitlines()]
    SimpleDocTemplate(str(path), title=str(message.get('Subject', 'Email'))).build(story)
    path.chmod(0o600)
    print(f'Saved PDF: {path}', file=sys.stderr)
    return path


def open_file(system, source):
    # Desktop openers return before their viewer has read NeoMutt's temporary file.
    path = save_unique(system.cache / 'opened', Path(source).name, Path(source).read_bytes())
    result = subprocess.run(['xdg-open', str(path)], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if result.returncode:
        raise MailError(f'Desktop viewer failed; cached file remains at {path}')


def open_html(system):
    message = read_message()
    part = message.get_body(preferencelist=('html',))
    if part is None:
        raise MailError('This message has no HTML body')
    path = save_unique(system.cache / 'html', uuid.uuid4().hex + '.html',
                       part.get_content().encode('utf-8'))
    result = subprocess.run(['xdg-open', str(path)], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if result.returncode:
        raise MailError(f'Browser failed; cached HTML remains at {path}')


def query_addresses(system, query):
    from email.utils import parseaddr
    matches = {}
    khard = system.run(['khard', '--config', system.integrations / 'khard/khard.conf',
                        'email', '--parsable', '--', query], check=False, timeout=20)
    for row in khard.stdout.splitlines():
        fields = row.split('\t')
        if len(fields) >= 2 and '@' in fields[0]:
            address = fields[0].strip()
            matches[address.casefold()] = (address, fields[1], 'Radicale contact')
    if system.database_exists() and query.strip():
        # Sender lookup is indexed. Escape user input as a literal regex, never shell code.
        search = 'not tag:spam and not tag:trash'
        history = system.nm('address', '--format=json', '--output=sender', '--deduplicate=address', search, check=False, timeout=20)
        if not history.returncode:
            for item in json.loads(history.stdout):
                address = item.get('address', '')
                haystack = (address + ' ' + (item.get('name') or '')).casefold()
                if address and all(term.casefold() in haystack for term in query.split()) and address.casefold() not in matches:
                    matches[address.casefold()] = (address, item.get('name') or address, 'Mail history; not a saved contact')
    rows = []
    for address, name, source in matches.values():
        clean = lambda s: ''.join(c for c in s if ord(c) >= 32 and ord(c) != 127)
        rows.append('\t'.join(map(clean, (address, name, source))))
    print(f'{len(rows)} address match(es)' if rows else 'No matching addresses')
    print('\n'.join(rows[:100]), end='\n' if rows else '')
    return bool(rows)
