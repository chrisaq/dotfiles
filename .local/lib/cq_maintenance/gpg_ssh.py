"""Short-lived SSH signing bridge using GPG's per-connection no-pinentry mode.

Only identities advertised by the existing GPG SSH agent are offered. Private
keys and cached passphrases stay in gpg-agent. No agent configuration is changed.
Protocol references: GnuPG agent OPTION/SETHASH/PKSIGN, OpenSSH agent protocol.
"""
from __future__ import annotations
import base64, contextlib, hashlib, os, re, shlex, socket, stat, struct
import tempfile, threading, urllib.parse
from pathlib import Path
from .util import Problem, runtime_dir

MAX_MESSAGE = 262144


def number(n):
    return struct.pack('>I', n)


def string(data):
    return number(len(data)) + data


class Reader:
    def __init__(self, data):
        self.data = data
        self.offset = 0

    def take(self, length):
        if length < 0 or self.offset + length > len(self.data):
            raise ValueError('Truncated SSH message')
        start = self.offset
        self.offset += length
        return self.data[start:self.offset]

    def uint(self):
        return struct.unpack('>I', self.take(4))[0]

    def string(self):
        return self.take(self.uint())

    def end(self):
        if self.offset != len(self.data):
            raise ValueError('Trailing SSH data')


def receive(stream, length):
    data = b''
    while len(data) < length:
        part = stream.recv(length - len(data))
        if not part:
            raise EOFError()
        data += part
    return data


def packet(stream):
    length = struct.unpack('>I', receive(stream, 4))[0]
    if not 0 < length <= MAX_MESSAGE:
        raise ValueError('Oversize SSH message')
    return receive(stream, length)


def sexp(data):
    """Parse GPG's canonical binary S-expression (not a printable expression)."""
    offset = 0
    def parse(depth=0):
        nonlocal offset
        if depth > 12 or offset >= len(data):
            raise ValueError('Invalid signature')
        if data[offset:offset+1] == b'(':
            offset += 1
            values = []
            while offset < len(data) and data[offset:offset+1] != b')':
                values.append(parse(depth+1))
            if offset >= len(data):raise ValueError('Unclosed signature')
            offset += 1
            return values
        colon = data.find(b':', offset, offset+10)
        if colon < 0 or not data[offset:colon].isdigit():raise ValueError('Invalid signature atom')
        length = int(data[offset:colon]);offset = colon+1
        value = data[offset:offset+length]
        if len(value) != length:raise ValueError('Truncated signature')
        offset += length
        return value
    result = parse()
    if offset != len(data):raise ValueError('Trailing signature data')
    return result


class AgentError(Exception):
    """Never include backend responses, PINs or signing payloads in diagnostics."""


class Assuan:
    def __init__(self, path, timeout=10):
        self.socket = socket.socket(socket.AF_UNIX)
        self.socket.settimeout(timeout)
        try:
            self.socket.connect(str(path));self.file = self.socket.makefile('rwb', buffering=0)
            self.response()
            self.command('OPTION pinentry-mode=error')
        except BaseException:
            self.close();raise

    def close(self):
        if hasattr(self, 'file'):self.file.close()
        self.socket.close()

    def response(self, inquiry=None):
        data = bytearray();statuses = []
        while True:
            line = self.file.readline(MAX_MESSAGE+1)
            if not line or len(line) > MAX_MESSAGE:raise AgentError()
            line = line.rstrip(b'\r\n')
            if line == b'OK' or line.startswith(b'OK '):return bytes(data), statuses
            if line.startswith(b'ERR'):raise AgentError()
            if line.startswith(b'D '):
                data.extend(urllib.parse.unquote_to_bytes(line[2:]))
                if len(data) > MAX_MESSAGE:raise AgentError()
            elif line.startswith(b'S '):statuses.append(line[2:].decode('ascii', errors='replace'))
            elif line.startswith(b'INQUIRE '):
                if inquiry is None or line != b'INQUIRE TBSDATA':
                    self.file.write(b'CAN\n');raise AgentError()
                for offset in range(0, len(inquiry), 128):
                    value = inquiry[offset:offset+128].replace(b'%', b'%25').replace(b'\r', b'%0D').replace(b'\n', b'%0A')
                    self.file.write(b'D '+value+b'\n')
                self.file.write(b'END\n')

    def command(self, command, inquiry=None):
        if '\n' in command or '\r' in command:raise ValueError('Invalid agent command')
        self.file.write(command.encode('ascii')+b'\n')
        return self.response(inquiry)


class SigningBridge:
    def __init__(self, agent_socket, ssh_socket):
        self.agent_socket = agent_socket
        self.ssh_socket = ssh_socket
        self.keys = {}
        self.blocked = False
        self.unavailable = False
        self.stop = threading.Event()
        self.clients = set()
        self.guard = threading.Lock()

    def identities(self):
        # Native SSH listing preserves sshcontrol/Use-for-ssh eligibility. It does
        # not sign or unlock anything. Confirmation-required keys are excluded.
        with socket.socket(socket.AF_UNIX) as sock:
            sock.settimeout(5);sock.connect(str(self.ssh_socket))
            sock.sendall(string(b'\x0b'));reader = Reader(packet(sock))
        if reader.take(1) != b'\x0c':raise AgentError()
        count = reader.uint()
        if count > 1024:raise AgentError()
        offered = {}
        for _ in range(count):
            blob, comment = reader.string(), reader.string()
            fingerprint = 'SHA256:'+base64.b64encode(hashlib.sha256(blob).digest()).decode().rstrip('=')
            offered[fingerprint] = (blob, comment)
        reader.end()
        with contextlib.closing(Assuan(self.agent_socket)) as agent:
            _, rows = agent.command('KEYINFO --list --with-ssh --ssh-fpr')
        for row in rows:
            fields = row.split()
            if len(fields) < 10 or fields[0] != 'KEYINFO':continue
            grip, fingerprint, flags = fields[1], fields[7], fields[9]
            if not re.fullmatch('[A-Fa-f0-9]{40}', grip) or any(f in flags for f in 'cD'):continue
            if fingerprint not in offered:continue
            blob, comment = offered[fingerprint]
            if Reader(blob).string() not in (b'ssh-rsa', b'ssh-ed25519'):continue
            self.keys[blob] = (grip, comment)

    def sign(self, blob, message, flags):
        if blob not in self.keys:raise AgentError()
        key = Reader(blob);algorithm = key.string()
        if algorithm == b'ssh-rsa':
            if flags not in (2, 4):raise AgentError()  # RSA/SHA-1 is deliberately refused.
            digest = 'sha512' if flags == 4 else 'sha256'
            identifier = b'rsa-sha2-512' if flags == 4 else b'rsa-sha2-256'
            key.string();modulus = key.string().lstrip(b'\0');key.end()
        elif algorithm == b'ssh-ed25519' and flags == 0:
            key.string();key.end();identifier = algorithm
        else:raise AgentError()
        with contextlib.closing(Assuan(self.agent_socket)) as agent:
            agent.command('SIGKEY '+self.keys[blob][0])
            if algorithm == b'ssh-rsa':
                agent.command('SETHASH --hash='+digest+' '+hashlib.new(digest, message).hexdigest())
            else:
                agent.command('SETHASH --inquire', inquiry=message)
            encoded, _ = agent.command('PKSIGN')
        result = sexp(encoded)
        if not isinstance(result, list) or result[0] != b'sig-val':raise AgentError()
        values = dict(result[1][1:])
        if algorithm == b'ssh-rsa':
            signature = values[b's'].lstrip(b'\0').rjust(len(modulus), b'\0')
            if len(signature) != len(modulus):raise AgentError()
        else:
            signature = values[b'r']+values[b's']
            if len(signature) != 64:raise AgentError()
        return string(identifier)+string(signature)

    def handle(self, request):
        reader = Reader(request);kind = reader.take(1)
        if kind == b'\x0b':
            reader.end()
            return b'\x0c'+number(len(self.keys))+b''.join(string(blob)+string(info[1]) for blob, info in self.keys.items())
        if kind == b'\x0d':
            blob, message, flags = reader.string(), reader.string(), reader.uint();reader.end()
            try:return b'\x0e'+string(self.sign(blob, message, flags))
            except (AgentError, OSError, ValueError, KeyError, TypeError, IndexError):
                self.blocked = True;return b'\x05'
        # No adding/removing keys, forwarding extensions or other agent operations.
        return b'\x05'

    def client(self, sock):
        try:
            sock.settimeout(10)
            while not self.stop.is_set():
                sock.sendall(string(self.handle(packet(sock))))
        except (OSError, EOFError, ValueError):pass
        finally:
            sock.close()
            with self.guard:self.clients.discard(sock)

    def serve(self):
        while not self.stop.is_set():
            try:sock, _ = self.listener.accept()
            except socket.timeout:continue
            except OSError:break
            with self.guard:self.clients.add(sock)
            threading.Thread(target=self.client, args=(sock,), daemon=True).start()

    def __enter__(self):
        try:self.identities()
        except (OSError, EOFError, AgentError, ValueError):self.unavailable = True
        root = runtime_dir();root.mkdir(parents=True, exist_ok=True, mode=0o700)
        info = root.lstat()
        if not stat.S_ISDIR(info.st_mode) or info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != 0o700:
            raise Problem('Unsafe runtime directory')
        self.directory = tempfile.TemporaryDirectory(prefix='gpg-', dir=root)
        self.path = str(Path(self.directory.name)/'agent')
        self.listener = socket.socket(socket.AF_UNIX);self.listener.settimeout(0.2)
        self.listener.bind(self.path);os.chmod(self.path, 0o600);self.listener.listen(4)
        self.thread = threading.Thread(target=self.serve, daemon=True);self.thread.start()
        command = shlex.join(['ssh', '-oBatchMode=yes', '-oIdentityAgent='+self.path,
                              '-oConnectTimeout=10', '-oNumberOfPasswordPrompts=0'])
        self.env = {'SSH_AUTH_SOCK':self.path, 'GIT_SSH_COMMAND':command}
        return self

    def __exit__(self, *args):
        self.stop.set();self.listener.close()
        with self.guard:
            for sock in self.clients:
                with contextlib.suppress(OSError):sock.shutdown(socket.SHUT_RDWR)
        self.thread.join(timeout=1);self.directory.cleanup()


def bridge(ctx):
    """Resolve sockets using GPG's homedir, never the desktop SSH_AUTH_SOCK."""
    from .config import xdg
    home = Path(ctx.options.get('gnupghome') or os.environ.get('GNUPGHOME') or
                (xdg('config')/'gnupg' if (xdg('config')/'gnupg').is_dir() else Path.home()/'.gnupg')).expanduser()
    result = ctx.run(['gpgconf', '--homedir', str(home), '--list-dirs'])
    paths = dict(line.split(':', 1) for line in result.stdout.splitlines() if ':' in line)
    if result.returncode or not all(name in paths for name in ('agent-socket', 'agent-ssh-socket')):
        raise Problem('GPG agent socket configuration unavailable')
    return SigningBridge(*(urllib.parse.unquote(paths[name]) for name in ('agent-socket', 'agent-ssh-socket')))
