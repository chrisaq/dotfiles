"""Shared configuration and the serialised mail/index pipeline."""
from __future__ import annotations

import configparser
import contextlib
import fcntl
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys
import stat
import time

ROOT = Path(__file__).resolve().parent


def helper_path():
    """Prefer the installed executable; keep the pre-install configuration usable."""
    installed = Path.home() / '.local/bin/cq_mailctl'
    return installed if installed.is_file() else ROOT / 'cq_mailctl'


class MailError(Exception):
    pass


def load_settings():
    path = Path(os.environ.get("CQ_MAIL_CONFIG", ROOT / "settings.json"))
    settings = json.loads(path.read_text())
    for key in ("mail_root", "password_store", "gnupghome", "attachments"):
        settings[key] = str(Path(settings[key]).expanduser().resolve())
    defaults = {"data": ("XDG_DATA_HOME", Path.home() / ".local/share"),
                "state": ("XDG_STATE_HOME", Path.home() / ".local/state"),
                "cache": ("XDG_CACHE_HOME", Path.home() / ".cache")}
    for key, (variable, default) in defaults.items():
        base = os.environ.get(variable, "")
        base = Path(base) if base and Path(base).is_absolute() else default
        settings[key] = str(Path(settings.get(key) or os.environ.get("CQ_MAIL_" + key.upper()) or base / "cq-mail").expanduser().resolve())
    runtime = settings.get("runtime") or os.environ.get("CQ_MAIL_RUNTIME")
    if not runtime:
        candidates = [os.environ.get("XDG_RUNTIME_DIR", ""), f"/run/user/{os.getuid()}"]
        for candidate in candidates:
            if candidate and Path(candidate).is_absolute() and private_directory(Path(candidate)):
                runtime = str(Path(candidate) / "cq-mail")
                break
        else:
            runtime = f"/tmp/cq-mail-{os.getuid()}"
    if not Path(runtime).is_absolute():
        raise MailError("Runtime path must be absolute")
    settings["runtime"] = str(Path(runtime))
    if "integrations" in settings:
        settings["integrations"] = str(Path(settings["integrations"]).expanduser().resolve())
    return settings


def private_directory(path):
    try:
        info = path.lstat()
    except FileNotFoundError:
        return False
    return stat.S_ISDIR(info.st_mode) and info.st_uid == os.getuid() and stat.S_IMODE(info.st_mode) == 0o700


def ensure_runtime(path):
    path.mkdir(parents=True, exist_ok=True, mode=0o700)
    if not private_directory(path):
        raise MailError(f"Runtime directory must be owned by this user, private (0700), and not a symlink: {path}")


def atomic_write(path, content, mode=0o600):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    temporary = path.with_name(path.name + f".{os.getpid()}.tmp")
    try:
        with temporary.open("x") as stream:
            os.chmod(temporary, mode)
            stream.write(content)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


class MailSystem:
    def __init__(self):
        self.settings = load_settings()
        self.data = Path(self.settings["data"])
        self.state = Path(self.settings["state"])
        self.cache = Path(self.settings["cache"])
        self.runtime = Path(self.settings["runtime"])
        self.database = self.data / "notmuch"
        self.mail_root = Path(self.settings["mail_root"])
        self.integrations = Path(self.settings.get('integrations', ROOT / 'integrations'))
        self.notmuch_config = self.integrations / "notmuch/config"
        self.scheduled = os.environ.get("CQ_MAIL_SCHEDULED") == "1"

    def environment(self):
        env = dict(os.environ)
        env.update(NOTMUCH_CONFIG=str(self.notmuch_config),
                   XDG_CONFIG_HOME=str(self.integrations),
                   PASSWORD_STORE_DIR=self.settings["password_store"],
                   GNUPGHOME=self.settings["gnupghome"],
                   GOPASS_CONFIG=str(self.integrations / "gopass.conf"),
                   GOPASS_CONFIG_NO_MIGRATE="1", GOPASS_NO_NOTIFY="1",
                   CHECKPOINT_DISABLE="1")
        for key in ("data", "state", "cache", "runtime"):
            env["CQ_MAIL_" + key.upper()] = self.settings[key]
        env.pop("GOPASS_DEBUG_LOG_SECRETS", None)
        return env

    def run(self, args, *, input=None, check=True, timeout=300, env=None, live=False):
        try:
            result = subprocess.run([str(a) for a in args], input=input, text=True,
                                    capture_output=not live, env=env or self.environment(),
                                    timeout=timeout)
        except (OSError, subprocess.TimeoutExpired) as error:
            raise MailError(f"{Path(str(args[0])).name} could not complete") from error
        if check and result.returncode:
            # Credentials and backend diagnostics never enter status or the journal.
            raise MailError(f"{Path(str(args[0])).name} failed (exit {result.returncode})")
        return result

    def nm(self, *args, **kwargs):
        return self.run(["notmuch", f"--config={self.notmuch_config}", *args], **kwargs)

    def tag_metadata(self, *args, **kwargs):
        """Folder/category bookkeeping must not rewrite per-copy Maildir flags."""
        config = configparser.RawConfigParser()
        config.optionxform = str
        config.read(self.notmuch_config)
        config['maildir']['synchronize_flags'] = 'false'
        from io import StringIO
        content = StringIO()
        config.write(content)
        path = self.integrations / 'notmuch/tagging.conf'
        atomic_write(path, content.getvalue())
        return self.run(['notmuch', f'--config={path}', 'tag', *args], **kwargs)

    @contextlib.contextmanager
    def lock(self, name="mail"):
        ensure_runtime(self.runtime)
        with open(self.runtime / f"{name}.lock", "a", opener=lambda path, flags: os.open(path, flags | os.O_NOFOLLOW, 0o600)) as stream:
            try:
                fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as error:
                raise MailError(f"{name} operation already running") from error
            yield

    def status(self, component, state, message):
        path = self.state / f"{component}-status.json"
        previous = json.loads(path.read_text()) if path.exists() else {}
        now = time.strftime("%Y-%m-%dT%H:%M:%S%z")
        previous.update(state=state, message=message, last_attempt=now)
        if state == "ok":
            previous["last_success"] = now
        atomic_write(path, json.dumps(previous, indent=2) + "\n")

    def secret(self, service):
        entry = self.settings["credentials"][service]
        if entry.startswith(("/", "-")) or any(p in ("", ".", "..") for p in entry.split("/")):
            raise MailError("Invalid credential entry")
        store = Path(self.settings["password_store"])
        path = store / (entry + ".gpg")
        if not path.is_file() or not path.resolve().is_relative_to(store.resolve()):
            raise MailError(f"Missing {service} credential entry")
        if self.scheduled:
            # Direct read of the standard store guarantees no pinentry or Git activity.
            result = self.run(["gpg", "--batch", "--pinentry-mode", "error", "--quiet",
                               "--decrypt", path], check=False, timeout=15)
        else:
            result = self.run(["gopass", "show", "--nosync", "--nofuzzysearch",
                               "--password", entry], check=False, timeout=120)
        if result.returncode or not result.stdout.splitlines():
            raise MailError(f"{service}: unlock required or credential unavailable; run manual sync")
        value = result.stdout.splitlines()[0]
        if not value or "\r" in value or "\0" in value:
            raise MailError(f"Invalid {service} credential")
        return value

    def database_exists(self):
        return (self.database / "xapian").is_dir()

    def reconcile(self):
        # Queries aggregate all copies of a Message-ID. They do not alter Maildir flags.
        system_tags = {"inbox": 'folder:""', "sent": 'folder:.Sent',
                       "spam": 'folder:.Spam', "trash": 'folder:.Trash'}
        lines = []
        for tag, query in system_tags.items():
            lines += [f"-{tag} -- tag:{tag} and not ({query})",
                      f"+{tag} -- ({query}) and not tag:{tag}"]
        self.tag_metadata("--batch", input="\n".join(lines) + "\n")

    def classify(self, query="tag:new", dry_run=False):
        args = ["afew", "--notmuch-config", str(self.notmuch_config), "--tag"]
        if dry_run:
            args += ["--dry-run", "--verbose"]
        result = self.run(args + [query], timeout=600)
        if not dry_run and query == 'tag:new':
            # Only acknowledge the queue after every rule succeeded.
            self.tag_metadata("-new", "--", query)
        return result.stdout + result.stderr if dry_run else result.stdout

    def index_locked(self):
        marker = self.state / 'bootstrap-complete'
        initial = not marker.exists()
        self.database.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.nm("new", "--no-hooks", timeout=1800)
        if initial:
            # Existing historical mail is previewed separately, never routed into Inbox.
            self.tag_metadata("+history-pending", "-new", "--", "tag:new")
            atomic_write(marker, 'Existing local mail queued for historical preview.\n')
        self.reconcile()
        self.classify()

    def index(self):
        with self.lock():
            self.status('index', 'running', 'Indexing local Maildirs')
            try:
                self.index_locked()
            except MailError as error:
                self.status('index', 'error', str(error))
                raise
            self.status('index', 'ok', 'Local index and folder tags refreshed')

    def after_new(self):
        with self.lock():
            self.reconcile()
            self.classify()

    def sync(self):
        try:
            with self.lock():
                # Preflight avoids launching a sync process that could ask for input.
                self.status("mail", "running", "Unlocking mail credentials")
                if not self.scheduled:
                    print("Mail: unlocking credentials…", file=sys.stderr, flush=True)
                self.secret("mail")
                if not self.database_exists():
                    self.index_locked()
                self.status("mail", "running", "Syncing Maildirs with IMAP server")
                if not self.scheduled:
                    print("Mail: syncing with IMAP server…", file=sys.stderr, flush=True)
                self.run(["mbsync", "--config", self.integrations / "mbsyncrc",
                          self.settings.get("channel_name", "primary")], timeout=1800, live=not self.scheduled)
                self.status("mail", "running", "Indexing and classifying synced mail")
                if not self.scheduled:
                    print("Mail: indexing and classifying…", file=sys.stderr, flush=True)
                self.index_locked()
            self.status("mail", "ok", "Mail synced, indexed and classified")
            if not self.scheduled:
                print("Mail: sync complete.", file=sys.stderr, flush=True)
        except MailError as error:
            self.status("mail", "unlock-required" if "unlock required" in str(error) else "error", str(error))
            raise

    def rule_preview(self, history=False):
        if not self.database_exists():
            raise MailError("No index yet; run cq_mailctl index first")
        base = "tag:history-pending" if history else "tag:new"
        rules = json.loads((ROOT / "rules.json").read_text())
        for rule in rules:
            condition = '' if rule['query'] == '*' else f" and ({rule['query']})"
            query = f"({base}){condition} and not tag:spam and not tag:trash"
            if 'header' in rule:
                import notmuch2
                with notmuch2.Database(self.database, config=self.notmuch_config) as database:
                    count = 0
                    for message in database.messages(query):
                        try:
                            count += bool(re.search(rule['pattern'], message.header(rule['header']), re.I))
                        except (LookupError, notmuch2.NullPointerError):
                            pass
                count = str(count)
            else:
                count = self.nm("count", query).stdout.strip()
            print(f"{count:>7}  {rule['tag']:<27} {rule['description']}")
        print("Category tags only; no moves, deletions, or read-state changes.")

    def apply_history(self):
        with self.lock():
            self.classify("tag:history-pending")
            self.tag_metadata("-history-pending", "--", "tag:history-pending")

    def doctor(self, credentials=False):
        checks = []
        for command in ("neomutt", "mbsync", "notmuch", "afew", "msmtp", "vdirsyncer",
                        "khard", "gopass", "gpg", "fzf", "lynx", "xdg-open"):
            checks.append((command, bool(shutil.which(command))))
        import importlib.util
        modules = ['vobject', 'reportlab']
        if any('header' in rule for rule in json.loads((ROOT / 'rules.json').read_text())):
            modules.append('notmuch2')
        for module in modules:
            checks.append((module, importlib.util.find_spec(module) is not None))
        checks += [("Maildir", (self.mail_root / "cur").is_dir()),
                   ("notmuch index", self.database_exists()),
                   ("password store", Path(self.settings["password_store"]).is_dir())]
        for service, entry in self.settings["credentials"].items():
            checks.append((f"{service} credential entry", (Path(self.settings["password_store"]) / (entry + ".gpg")).is_file()))
        if credentials:
            for service in self.settings["credentials"]:
                try:
                    self.secret(service)
                    checks.append((service + " credential readable", True))
                except MailError:
                    checks.append((service + " credential readable (unlock required)", False))
        for label, ok in checks:
            print(f"{'OK     ' if ok else 'MISSING'} {label}")
        for name in ("mail", "index", "contacts"):
            path = self.state / f"{name}-status.json"
            if path.exists():
                print(name + ": " + path.read_text().strip())
        return all(ok for _, ok in checks)

    def check_connections(self, authenticate=True):
        """Verify TLS endpoints and optionally authenticate; never send a message."""
        import imaplib
        import smtplib
        import ssl
        settings = self.settings
        password = self.secret('mail') if authenticate else None
        context = ssl.create_default_context()
        for protocol in ('IMAP', 'SMTP'):
            try:
                if protocol == 'IMAP':
                    with imaplib.IMAP4_SSL(settings['imap_host'], 993, ssl_context=context, timeout=20) as client:
                        if authenticate:
                            client.login(settings['imap_username'], password)
                else:
                    with smtplib.SMTP(settings['smtp_host'], settings['smtp_port'], timeout=20) as client:
                        client.ehlo()
                        client.starttls(context=context)
                        client.ehlo()
                        if authenticate:
                            client.login(settings['imap_username'], password)
            except (OSError, imaplib.IMAP4.error, smtplib.SMTPException) as error:
                raise MailError(f'{protocol} TLS/authentication check failed; verify endpoint, network and credential entry') from error
            print(f'{protocol}: TLS verified' + (' and authentication succeeded' if authenticate else ' (authentication not checked)'))
