"""Read-only address book mirroring and explicit single-contact publication."""
from __future__ import annotations

from email.utils import getaddresses
import json
from pathlib import Path
import shutil
import sys
import tempfile
import uuid

from mailcore import MailError, MailBusy, MailUnlockRequired, atomic_write, helper_path
from mailui import read_message, Terminal


def email_addresses(directory):
    import vobject
    found = set()
    for path in Path(directory).glob('*.vcf'):
        try:
            card = vobject.readOne(path.read_text())
            found.update(str(item.value).strip().casefold() for item in card.contents.get('email', []))
        except Exception as error:
            # A malformed existing card must not weaken duplicate detection.
            raise MailError(f'Cannot parse existing contact {path.name}') from error
    return found


def snapshot(directory):
    return {p.name: p.read_bytes() for p in Path(directory).glob('*.vcf')}


def validate_addition(directory, baseline, new_name):
    current = snapshot(directory)
    if set(current) != set(baseline) | {new_name}:
        raise MailError('Publication refused: expected exactly one new contact')
    if any(current[name] != data for name, data in baseline.items()):
        raise MailError('Publication refused: an existing contact changed')


def sync_mirror(system):
    system.secret('contacts')
    system.run(['vdirsyncer', '--config', system.integrations / 'vdirsyncer/config',
                'discover', 'contacts'], timeout=600)
    system.run(['vdirsyncer', '--config', system.integrations / 'vdirsyncer/config',
                'sync', 'contacts'], timeout=600)


def sync(system):
    try:
        with system.lock('contacts'):
            sync_mirror(system)
            system.status('contacts', 'ok', 'Read-only Radicale mirror refreshed')
    except MailBusy:
        raise
    except MailError as error:
        system.status('contacts', 'unlock-required' if isinstance(error, MailUnlockRequired) else 'error', str(error))
        raise


def publication_config(system, workspace, writable=False):
    settings = system.settings
    partial = '' if writable else 'partial_sync = "revert"'
    content = f'''[general]
status_path = {json.dumps(str(workspace / 'status'))}
[pair publish]
a = "local"
b = "remote"
collections = null
{partial}
[storage local]
type = "filesystem"
path = {json.dumps(str(workspace / 'book'))}
fileext = ".vcf"
[storage remote]
type = "carddav"
url = {json.dumps(settings['contacts_url'])}
username = {json.dumps(settings['contacts_username'])}
password.fetch = ["command", {json.dumps(str(helper_path()))}, "credential", "contacts"]
read_only = {'false' if writable else 'true'}
'''
    path = workspace / 'vdirsyncer.conf'
    atomic_write(path, content)
    return path


def make_card(name, address):
    import vobject
    card = vobject.vCard()
    card.add('uid').value = str(uuid.uuid4())
    card.add('fn').value = name
    card.add('n').value = vobject.vcard.Name(family=name)
    card.add('email').value = address
    card.email.type_param = 'INTERNET'
    return card.uid.value + '.vcf', card.serialize().encode('utf-8')


def add_sender(system):
    if system.scheduled:
        raise MailError('Contact publication is interactive only')
    message = read_message()
    senders = getaddresses(message.get_all('from', []))
    if len(senders) != 1 or '@' not in senders[0][1]:
        raise MailError('Expected one valid From address')
    name, address = senders[0]
    if any(ord(c) < 32 for c in name + address):
        raise MailError('Sender contains control characters')
    name = name or address.split('@', 1)[0]
    with system.lock('contacts'):
        system.secret('contacts')
        with tempfile.TemporaryDirectory(prefix='publish-', dir=system.runtime) as temporary:
            workspace = Path(temporary)
            book = workspace / 'book'
            book.mkdir(mode=0o700)
            config = publication_config(system, workspace)
            pull = ['vdirsyncer', '--config', config, 'sync', 'publish']
            system.run(['vdirsyncer', '--config', config, 'discover', 'publish'], timeout=600)
            system.run(pull, timeout=600)
            if address.casefold() in email_addresses(book):
                print('This sender is already a saved contact.', file=sys.stderr)
                return
            with Terminal() as terminal:
                def prompt(text):
                    terminal.write(text)
                    terminal.flush()
                    answer = terminal.readline()
                    if not answer:
                        raise MailError('Contact entry cancelled')
                    return answer.rstrip('\n')
                terminal.write('Save one contact to your existing Radicale / DAVx5 address book.\n')
                name = prompt(f'Name [{name}]: ').strip() or name
                address = prompt(f'Email [{address}]: ').strip() or address
                parsed = getaddresses([address])
                if len(parsed) != 1 or parsed[0][1] != address or '@' not in address or any(ord(c) < 32 for c in name + address):
                    raise MailError('Invalid contact name or email address')
                terminal.write(f'\nProposed contact: {name} <{address}>\n')
                if prompt('Publish this contact to your phone address book? [y/N] ').casefold() not in ('y', 'yes'):
                    terminal.write('Cancelled. Nothing published.\n')
                    return
            # Refresh again after user interaction. No local contact exists yet.
            system.run(pull, timeout=600)
            if address.casefold() in email_addresses(book):
                print('This address is already present; nothing published.', file=sys.stderr)
                return
            baseline = snapshot(book)
            filename, data = make_card(name, address)
            path = book / filename
            with path.open('xb') as stream:
                path.chmod(0o600)
                stream.write(data)
            validate_addition(book, baseline, filename)
            publication_config(system, workspace, writable=True)
            try:
                system.run(['vdirsyncer', '--config', config, 'discover', 'publish'], timeout=600)
                system.run(pull, timeout=600)
            except MailError:
                drafts = system.data / 'contact-drafts'
                drafts.mkdir(parents=True, exist_ok=True, mode=0o700)
                saved = drafts / filename
                shutil.copy2(path, saved)
                saved.chmod(0o600)
                print(f'Publication could not be confirmed. Draft retained at {saved}; refresh before retrying.', file=sys.stderr)
                raise
        print('Contact published. DAVx5 will receive it on its next sync.', file=sys.stderr)
        try:
            sync_mirror(system)
            system.status('contacts', 'ok', 'One reviewed contact published; mirror refreshed')
        except MailError:
            system.status('contacts', 'error', 'Contact published; local mirror refresh still needed')
            print('Publication succeeded; run contacts sync to refresh completion.', file=sys.stderr)
