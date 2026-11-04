import contextlib,json,os,subprocess,sys,tempfile,time,tomllib,unittest
from pathlib import Path
from unittest.mock import patch,Mock
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
from cq_maintenance import config,engine
from cq_maintenance.model import Check,Result,now
from cq_maintenance.providers.base import Context
from cq_maintenance.util import atomic_json,state_dir,Problem,lock
from cq_maintenance.view import payload

class Isolated(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.home=Path(self.tmp.name)
        self.env=patch.dict(os.environ,{'HOME':str(self.home),'XDG_CONFIG_HOME':str(self.home/'config'),'XDG_STATE_HOME':str(self.home/'state'),'XDG_CACHE_HOME':str(self.home/'cache'),'XDG_RUNTIME_DIR':str(self.home/'runtime'),'CQ_MAINTENANCE_CONFIG':str(self.home/'config/config.toml')},clear=False);self.env.start();self.addCleanup(self.env.stop)
        (self.home/'runtime').mkdir(mode=0o700)
        self.settings=Mock();self.settings.checks={'test':Check(provider='command')};self.settings.max_workers=2;self.settings.waybar_signal=12
        patcher=patch('cq_maintenance.engine.load',return_value=self.settings);patcher.start();self.addCleanup(patcher.stop)
        patcher=patch('cq_maintenance.engine.signal_bar');patcher.start();self.addCleanup(patcher.stop)

class EngineTests(Isolated):
    def test_disabled_excluded_and_stale_never_green(self):
        engine.save(Result(id='test',state='ok',summary='old',checked_at=now()-1000))
        atomic_json(state_dir()/'collector.json',{'heartbeat':now()})
        self.assertEqual(engine.snapshot(self.settings)[0].state,'unknown')
        self.settings.checks['test'].enabled=False
        self.assertEqual(engine.snapshot(self.settings),[])
        self.assertEqual(engine.snapshot(self.settings,True)[0].state,'disabled')
    def test_collector_uses_provider_and_does_not_execute_fixes(self):
        provider=Mock();provider.check.side_effect=lambda ctx:ctx.result('pending','work waiting')
        with patch('cq_maintenance.engine.get',return_value=provider):engine.collect()
        provider.execute.assert_not_called()
        self.assertEqual(engine.previous('test').state,'pending')
    def test_failure_does_not_leak_exception_body(self):
        provider=Mock();provider.check.side_effect=RuntimeError('secret api key')
        with patch('cq_maintenance.engine.get',return_value=provider):engine.collect()
        self.assertNotIn('secret',engine.result_path('test').read_text())
    def test_check_and_fix_share_lock(self):
        with lock('test'):
            result=engine.check_one('test',self.settings.checks['test'])
        self.assertIn('already running',result.summary)
    def test_safe_batch_excludes_upgrade(self):
        from cq_maintenance.model import Action
        provider=Mock();provider.check.side_effect=lambda ctx:ctx.result('pending','updates',actions=[Action(id='upgrade',label='Upgrade',safe=False)])
        with patch('cq_maintenance.engine.get',return_value=provider):rows=engine.fix()
        provider.execute.assert_not_called();self.assertEqual(rows[0]['state'],'skipped')
    def test_unavailable_crypto_blocks_dependent_mail_but_not_other_checks(self):
        from cq_maintenance.model import Action
        self.settings.checks={'crypt-sync':Check(provider='crypt'),'mail':Check(provider='mail'),'other':Check(provider='command')}
        provider=Mock()
        provider.check.side_effect=lambda ctx:ctx.result('unknown','Unavailable') if ctx.id=='crypt-sync' else ctx.result('pending','Ready',actions=[Action(id='fix',label='Sync',safe=True)])
        provider.execute.return_value='Done'
        with patch('cq_maintenance.engine.get',return_value=provider):rows=engine.fix()
        self.assertEqual(next(row for row in rows if row['id']=='mail')['state'],'blocked')
        self.assertEqual(next(row for row in rows if row['id']=='other')['state'],'completed')
        self.assertEqual(provider.execute.call_count,1)
    def test_after_repair_bypasses_provider_cache(self):
        from cq_maintenance.model import Action
        provider=Mock();provider.execute.return_value='Synced'
        provider.check.side_effect=lambda ctx:ctx.result('ok' if ctx.force else 'pending','Fresh' if ctx.force else 'Cached',actions=[Action(id='fix',label='Sync',safe=True)])
        with patch('cq_maintenance.engine.get',return_value=provider):engine.fix(['test'])
        self.assertEqual(engine.previous('test').state,'ok')
    def test_existing_mail_sync_is_accepted_without_second_operation(self):
        from cq_maintenance.providers import mail
        ctx=Context('mail',Check(provider='mail'),checking=False)
        with patch.object(Context,'run',return_value=subprocess.CompletedProcess([],75)) as run:
            self.assertIn('already running',mail.execute(ctx,'fix'))
        self.assertEqual(run.call_count,1)
    def test_bar_is_escaped_and_missing_checks_are_unknown(self):
        value=payload([Result(id='x',state='error',summary='<bad & value>')])
        self.assertIn('&lt;bad &amp; value&gt;',value['tooltip'])
        self.assertEqual(payload([])['alt'],'disabled')
    def test_toggle_keeps_shared_config_unchanged(self):
        path=config.config_path();path.parent.mkdir();path.write_text('[checks.test]\nprovider="command"\nenabled=true\n')
        original=path.read_bytes();config.toggle('test',False)
        self.assertEqual(path.read_bytes(),original)
        self.assertFalse(config.load().checks['test'].enabled)
    def test_background_commands_cannot_invoke_desktop_ssh_agent(self):
        from cq_maintenance.util import run
        result=run([sys.executable,'-c','import os; print(os.environ["GIT_SSH_COMMAND"])'])
        self.assertIn('-oBatchMode=yes',result.stdout)
        self.assertIn('-oIdentityAgent=none',result.stdout)
    def test_custom_output_cannot_supply_commands(self):
        from cq_maintenance.providers import command
        ctx=Context('test',Check(provider='command',options={'check':['true']}))
        output=json.dumps({'state':'ok','summary':'fine','actions':[{'argv':['rm','-rf','/']}]})
        with patch.object(Context,'run',return_value=subprocess.CompletedProcess([],0,output,'')):
            result=command.check(ctx)
        self.assertEqual(result.actions,[])

class GitTests(Isolated):
    def git(self,args,cwd=None):
        return subprocess.check_output(['git',*args],cwd=cwd,text=True,stderr=subprocess.DEVNULL).strip()
    def setUp(self):
        super().setUp();self.remote=self.home/'remote.git';self.git(['init','--bare',str(self.remote)])
        self.work=self.home/'work';self.git(['clone',str(self.remote),str(self.work)])
        self.git(['config','user.name','Test'],self.work);self.git(['config','user.email','test@example.org'],self.work)
        (self.work/'one').write_text('one');self.git(['add','one'],self.work);self.git(['commit','-m','initial'],self.work);self.git(['push','-u','origin','HEAD'],self.work)
        self.ctx=Context('test',Check(provider='git',options={'git_dir':str(self.work/'.git'),'work_tree':str(self.work)}))
    def test_fetch_does_not_change_working_files_and_dirty_blocks_fix(self):
        from cq_maintenance.providers import git
        (self.work/'one').write_text('local edit')
        result=git.check(self.ctx)
        self.assertEqual((self.work/'one').read_text(),'local edit')
        self.assertEqual(result.metrics['dirty'],1)
        with self.assertRaises(Problem):git.execute(self.ctx,'fix')
    def test_unsafe_refspec_is_not_fetched(self):
        from cq_maintenance.providers import git
        self.git(['config','remote.origin.fetch','+refs/heads/*:refs/heads/*'],self.work)
        before=self.git(['rev-parse','HEAD'],self.work)
        result=git.check(self.ctx)
        self.assertEqual(result.state,'unknown');self.assertEqual(before,self.git(['rev-parse','HEAD'],self.work))
    def test_fast_forward_works_only_without_local_changes(self):
        from cq_maintenance.providers import git
        other=self.home/'other';self.git(['clone',str(self.remote),str(other)])
        self.git(['config','user.name','Test'],other);self.git(['config','user.email','test@example.org'],other)
        (other/'two').write_text('two');self.git(['add','two'],other);self.git(['commit','-m','remote'],other);self.git(['push'],other)
        result=git.check(self.ctx);self.assertEqual(result.metrics['behind'],1)
        self.assertFalse((self.work/'two').exists())
        git.execute(self.ctx,'fix');self.assertTrue((self.work/'two').exists())
    def test_ssh_unlock_failure_preserves_verification_and_retries_after_unlock(self):
        from cq_maintenance.providers import git
        from cq_maintenance import gpg_ssh
        self.git(['remote','set-url','origin','git@example.invalid:repo.git'],self.work)
        verified=now()-1000
        self.ctx.previous=Result(id='test',state='ok',summary='old',metrics={'remote_checked_at':verified,'remote_attempt_at':verified})
        signing=Mock();signing.env={};signing.keys={'public':None};signing.unavailable=False;signing.blocked=True
        original=Context.run
        def call(ctx,args,**kwargs):
            if 'fetch' in args:return subprocess.CompletedProcess(args,255 if signing.blocked else 0,'','')
            return original(ctx,args,**kwargs)
        manager=Mock();manager.__enter__=Mock(return_value=signing);manager.__exit__=Mock(return_value=False)
        with patch.object(gpg_ssh,'bridge',return_value=manager),patch.object(Context,'run',autospec=True,side_effect=call):
            result=git.check(self.ctx)
            self.assertEqual(result.state,'warning');self.assertEqual(result.metrics['dirty'],0)
            self.assertEqual(result.metrics['remote_checked_at'],verified)
            self.assertIn('SSH unlock required',result.summary)
            result.metrics['remote_attempt_at']=now()-61
            signing.blocked=False
            fresh=git.check(Context('test',self.ctx.config,result))
        self.assertEqual(fresh.state,'ok');self.assertGreater(fresh.metrics['remote_checked_at'],verified)
    def test_divergence_requires_review(self):
        from cq_maintenance.providers import git
        other=self.home/'other';self.git(['clone',str(self.remote),str(other)])
        self.git(['config','user.name','Test'],other);self.git(['config','user.email','test@example.org'],other)
        (other/'two').write_text('remote');self.git(['add','two'],other);self.git(['commit','-m','remote'],other);self.git(['push'],other)
        (self.work/'three').write_text('local');self.git(['add','three'],self.work);self.git(['commit','-m','local'],self.work)
        self.assertEqual(git.check(self.ctx).state,'error')
        with self.assertRaises(Problem):git.execute(self.ctx,'fix')

class PackageTests(Isolated):
    def test_checkupdates_uses_private_database_and_no_root(self):
        from cq_maintenance.providers import packages
        ctx=Context('test',Check(provider='packages',options={'kind':'arch'}))
        with patch.object(Context,'run',return_value=subprocess.CompletedProcess([],2,'','')) as run:
            result=packages.check(ctx)
        self.assertEqual(result.state,'ok');self.assertEqual(run.call_args.args[0][0],'checkupdates')
        self.assertIn(str(self.home/'cache'),run.call_args.kwargs['env']['CHECKUPDATES_DB'])
    def test_update_failure_is_not_up_to_date(self):
        from cq_maintenance.providers import packages
        with patch.object(Context,'run',return_value=subprocess.CompletedProcess([],1,'','')):
            with self.assertRaises(Problem):packages.check(Context('test',Check(provider='packages')))
