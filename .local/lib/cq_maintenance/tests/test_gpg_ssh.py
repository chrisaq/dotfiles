"""Exercise real GPG/OpenSSH signing using disposable keys and a trap pinentry."""
import contextlib, os, shutil, subprocess, unittest
from pathlib import Path
from unittest.mock import patch
from test_engine import Isolated
from cq_maintenance import gpg_ssh
from cq_maintenance.providers.base import Context
from cq_maintenance.model import Check


@unittest.skipUnless(all(shutil.which(tool) for tool in ['gpg','gpgconf','gpg-connect-agent','ssh-keygen']), 'GPG/OpenSSH required')
class SigningTests(Isolated):
    def setUp(self):
        super().setUp()
        self.gnupg=self.home/'gnupg';self.gnupg.mkdir(mode=0o700)
        self.environment=patch.dict(os.environ,{'GNUPGHOME':str(self.gnupg)})
        self.environment.start();self.addCleanup(self.environment.stop)
        self.addCleanup(lambda:subprocess.run(['gpgconf','--homedir',str(self.gnupg),'--kill','gpg-agent'],capture_output=True))
        pinentry=self.home/'pinentry'
        pinentry.write_text('#!/bin/sh\ntouch "'+str(self.home/'pinentry-called')+'"\nexit 1\n');pinentry.chmod(0o700)
        (self.gnupg/'gpg-agent.conf').write_text('enable-ssh-support\npinentry-program '+str(pinentry)+'\n')
        self.ctx=Context('test',Check(provider='git',options={'gnupghome':str(self.gnupg)}))

    def prepare(self, algorithm):
        subprocess.run(['gpg','--batch','--pinentry-mode','loopback','--passphrase','test-only',
                        '--quick-generate-key','Maintenance <test@example.invalid>',algorithm,'sign,auth','0'],capture_output=True,check=True)
        listing=subprocess.run(['gpg','--batch','--with-colons','--with-keygrip','--list-secret-keys'],capture_output=True,text=True,check=True).stdout
        grip=next(line.split(':')[9] for line in listing.splitlines() if line.startswith('grp:'))
        self.fingerprint=next(line.split(':')[9] for line in listing.splitlines() if line.startswith('fpr:'))
        (self.gnupg/'sshcontrol').write_text(grip+'\n')
        self.payload=self.home/'payload';self.payload.write_bytes(b'cq maintenance SSH signing test\n')
        # Kill only this disposable agent, clearing the generation-time cache.
        subprocess.run(['gpgconf','--homedir',str(self.gnupg),'--kill','gpg-agent'],capture_output=True,check=True)
        subprocess.run(['gpg-connect-agent','--homedir',str(self.gnupg),'/bye'],capture_output=True,check=True)
        return grip

    def exercise(self, algorithm):
        grip=self.prepare(algorithm)
        with gpg_ssh.bridge(self.ctx) as bridge:
            self.assertFalse(bridge.unavailable);self.assertEqual(len(bridge.keys),1)
            blob=next(iter(bridge.keys))
            with self.assertRaises(gpg_ssh.AgentError):bridge.sign(blob,b'locked test',2 if algorithm.startswith('rsa') else 0)
        self.assertFalse((self.home/'pinentry-called').exists())
        # Unlock in this fixture through GPG loopback, as an interactive unlock
        # would. No secret material is exported to the bridge.
        subprocess.run(['gpg','--batch','--yes','--pinentry-mode','loopback','--passphrase','test-only',
                        '--local-user',self.fingerprint+'!','--output',str(self.home/'gpg-signature'),
                        '--detach-sign',str(self.payload)],capture_output=True,check=True)
        with gpg_ssh.bridge(self.ctx) as bridge:
            blob=next(iter(bridge.keys));kind=gpg_ssh.Reader(blob).string()
            import base64
            public=kind+b' '+base64.b64encode(blob)
            key=self.home/'public';key.write_bytes(public+b'\n')
            env=dict(os.environ,**bridge.env)
            signed=subprocess.run(['ssh-keygen','-Y','sign','-U','-f',str(key),'-n','cq-maintenance',str(self.payload)],env=env,capture_output=True,text=True)
            self.assertEqual(signed.returncode,0,signed.stderr)
            allowed=self.home/'allowed';allowed.write_bytes(b'test '+public+b'\n')
            verified=subprocess.run(['ssh-keygen','-Y','verify','-f',str(allowed),'-I','test','-n','cq-maintenance','-s',str(self.payload)+'.sig'],input=self.payload.read_bytes(),capture_output=True)
            self.assertEqual(verified.returncode,0,verified.stderr)
            # Expire the cache after identities were loaded: the signing operation
            # must still refuse pinentry instead of relying on a racy preflight.
            subprocess.run(['gpgconf','--homedir',str(self.gnupg),'--kill','gpg-agent'],capture_output=True,check=True)
            subprocess.run(['gpg-connect-agent','--homedir',str(self.gnupg),'/bye'],capture_output=True,check=True)
            with self.assertRaises(gpg_ssh.AgentError):bridge.sign(blob,b'expired cache',2 if algorithm.startswith('rsa') else 0)
        self.assertFalse((self.home/'pinentry-called').exists())

    def test_locked_then_unlocked_rsa_without_pinentry(self):self.exercise('rsa2048')
    def test_locked_then_unlocked_ed25519_without_pinentry(self):self.exercise('ed25519')


class ProtocolTests(unittest.TestCase):
    def test_oversize_and_malformed_messages_fail_closed(self):
        with self.assertRaises(ValueError):gpg_ssh.Reader(b'\0\0\0\x10short').string()
        with self.assertRaises(ValueError):gpg_ssh.sexp(b'(3:abc')
    def test_unknown_identity_cannot_sign(self):
        bridge=gpg_ssh.SigningBridge('/unused','/unused')
        response=bridge.handle(b'\x0d'+gpg_ssh.string(b'unknown')+gpg_ssh.string(b'payload')+gpg_ssh.number(2))
        self.assertEqual(response,b'\x05');self.assertTrue(bridge.blocked)
    def test_add_key_requests_are_refused(self):
        bridge=gpg_ssh.SigningBridge('/unused','/unused')
        self.assertEqual(bridge.handle(b'\x11arbitrary'),b'\x05')


class ConfirmationTests(SigningTests):
    # Avoid inheriting the RSA/Ed25519 tests a second time.
    test_locked_then_unlocked_rsa_without_pinentry=None
    test_locked_then_unlocked_ed25519_without_pinentry=None
    def test_confirmation_required_key_is_not_offered(self):
        grip=self.prepare('ed25519')
        (self.gnupg/'sshcontrol').write_text(grip+' 0 confirm\n')
        with gpg_ssh.bridge(self.ctx) as bridge:self.assertEqual(bridge.keys,{})
        self.assertFalse((self.home/'pinentry-called').exists())
