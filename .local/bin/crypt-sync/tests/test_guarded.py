"""Guarded crypt-sync; only disposable homes and fake cryptographic payloads."""
import importlib.util,os,subprocess,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
spec=importlib.util.spec_from_file_location('guarded',Path(__file__).resolve().parents[1]/'crypt-sync-state.py')
guarded=importlib.util.module_from_spec(spec);spec.loader.exec_module(guarded)

class GuardedSync(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup);self.home=Path(self.temp.name)
        self.local=self.home/'config';self.vault=self.home/'store/ConfigFiles/config.gpg';self.vault.parent.mkdir(parents=True)
        self.lists=self.home/'bin/crypt-sync';self.lists.mkdir(parents=True)
        (self.lists/'crypt-sync-list.txt').write_text('config.gpg:config\n')
        env={'HOME':str(self.home),'PASSWORD_STORE_DIR':str(self.home/'store'),'XDG_BIN_HOME':str(self.home/'bin'),'XDG_STATE_HOME':str(self.home/'state')}
        p=patch.dict(os.environ,env);p.start();self.addCleanup(p.stop)
    def fake_gpg(self,args,**kwargs):
        data=Path(args[-1]).read_bytes()
        payload=b'cipher:'+data if '--encrypt' in args else data.removeprefix(b'cipher:')
        if '--output' in args:Path(args[args.index('--output')+1]).write_bytes(payload);payload=b''
        return subprocess.CompletedProcess(args,0,payload,b'')
    def inspect(self):return guarded.status()['entries'][0]['state']
    def transfer(self):
        with patch.object(guarded,'gpg',side_effect=self.fake_gpg):guarded.transfer(self.local,self.vault,'encrypt')
    def test_check_does_not_decrypt_or_create_state(self):
        self.local.write_text('secret')
        with patch.object(guarded,'gpg',side_effect=AssertionError('decryption')):self.assertEqual(self.inspect(),'encrypt')
        self.assertFalse(guarded.root().exists())
    def test_initial_transfer_establishes_verified_baseline(self):
        self.local.write_text('secret');self.transfer()
        self.assertEqual(self.inspect(),'ok');self.assertEqual(self.vault.stat().st_mode & 0o777,0o600)
    def test_unchanged_timestamp_does_not_hide_local_edit(self):
        self.local.write_text('one');self.transfer();stamp=self.local.stat().st_mtime_ns
        self.local.write_text('two');os.utime(self.local,ns=(stamp,stamp))
        self.assertEqual(self.inspect(),'encrypt')
    def test_two_sided_changes_are_not_overwritten(self):
        self.local.write_text('one');self.transfer()
        self.local.write_text('local');self.vault.write_text('cipher:remote')
        with patch('sys.argv',['helper','--safe']),patch.object(guarded,'gpg',side_effect=AssertionError('must not decrypt')):
            self.assertEqual(guarded.main(),1)
        self.assertEqual(self.local.read_text(),'local');self.assertEqual(self.vault.read_text(),'cipher:remote')
    def test_matching_unverified_pair_can_be_verified_in_memory(self):
        self.local.write_text('one');self.vault.write_text('cipher:one')
        self.assertEqual(self.inspect(),'unverified')
        with patch.object(guarded,'gpg',side_effect=self.fake_gpg):self.assertTrue(guarded.verify(self.local,self.vault))
        self.assertEqual(self.inspect(),'ok')
    def test_invalid_symlink_is_refused(self):
        target=self.home/'target';target.write_text('keep');self.local.symlink_to(target)
        self.assertEqual(self.inspect(),'invalid')
        with self.assertRaises(guarded.Blocked):guarded.transfer(self.local,self.vault,'encrypt')
        self.assertEqual(target.read_text(),'keep')
    def test_source_race_leaves_old_destination_intact(self):
        self.local.write_text('one');self.transfer();old=self.vault.read_bytes();self.local.write_text('two')
        def race(args,**kwargs):
            response=self.fake_gpg(args,**kwargs);self.local.write_text('external edit');return response
        with patch.object(guarded,'gpg',side_effect=race):
            with self.assertRaises(guarded.Blocked):guarded.transfer(self.local,self.vault,'encrypt')
        self.assertEqual(self.vault.read_bytes(),old);self.assertFalse(list(self.vault.parent.glob('.crypt-sync-guarded-*')))
    def test_mismatch_remains_unverified(self):
        self.local.write_text('local');self.vault.write_text('cipher:remote')
        with patch.object(guarded,'gpg',side_effect=self.fake_gpg):self.assertFalse(guarded.verify(self.local,self.vault))
        self.assertEqual(self.inspect(),'unverified')
