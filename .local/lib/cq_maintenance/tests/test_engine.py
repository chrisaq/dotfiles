import contextlib,json,os,subprocess,sys,tempfile,time,tomllib,unittest
from pathlib import Path
from unittest.mock import patch,Mock
sys.path.insert(0,str(Path(__file__).resolve().parents[2]))
from cq_maintenance import config,engine
from cq_maintenance.model import Check,Result,now
from cq_maintenance.providers.base import Context
from cq_maintenance.util import atomic_json,state_dir,Problem,lock,read_json
from cq_maintenance.view import payload

class Isolated(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.home=Path(self.tmp.name)
        self.env=patch.dict(os.environ,{'HOME':str(self.home),'XDG_CONFIG_HOME':str(self.home/'config'),'XDG_STATE_HOME':str(self.home/'state'),'XDG_CACHE_HOME':str(self.home/'cache'),'XDG_RUNTIME_DIR':str(self.home/'runtime'),'CQ_MAINTENANCE_CONFIG':str(self.home/'config/config.toml')},clear=False);self.env.start();self.addCleanup(self.env.stop)
        (self.home/'runtime').mkdir(mode=0o700)
        self.settings=Mock();self.settings.setup={};self.settings.checks={'test':Check(provider='command')};self.settings.max_workers=2;self.settings.waybar_signal=12
        patcher=patch('cq_maintenance.engine.load',return_value=self.settings);patcher.start();self.addCleanup(patcher.stop)
        patcher=patch('cq_maintenance.engine.signal_bar');patcher.start();self.addCleanup(patcher.stop)

class EngineTests(Isolated):
    def test_disabled_excluded_and_stale_never_green(self):
        engine.save(Result(id='test',state='ok',summary='old',checked_at=now()-1000))
        atomic_json(state_dir()/'collector.json',{'heartbeat':now()})
        self.assertEqual(next(r for r in engine.snapshot(self.settings) if r.id=='test').state,'unknown')
        self.settings.checks['test'].enabled=False
        self.assertEqual(engine.snapshot(self.settings),[])
        self.assertEqual(engine.snapshot(self.settings,True)[0].state,'disabled')
    def test_collector_uses_provider_and_does_not_execute_fixes(self):
        provider=Mock();provider.check.side_effect=lambda ctx:ctx.result('pending','work waiting')
        with patch('cq_maintenance.engine.get',return_value=provider):engine.collect()
        provider.execute.assert_not_called()
        self.assertEqual(engine.previous('test').state,'pending')
    def test_fast_check_publishes_before_slow_batch_finishes(self):
        import threading
        self.settings.checks={'fast':Check(provider='command'),'slow':Check(provider='command')}
        slow_started=threading.Event();release=threading.Event();published=threading.Event();errors=[]
        provider=Mock()
        def check(ctx):
            if ctx.id=='slow':slow_started.set();release.wait(5)
            else:self.assertTrue(slow_started.wait(3))
            return ctx.result('ok','Complete')
        provider.check.side_effect=check
        def notify(number):
            current=engine.previous('fast')
            if current and current.state=='ok':
                active=read_json(state_dir()/'jobs/fast.json')
                self.assertFalse(active['active']);published.set()
        def collect():
            try:engine.collect()
            except Exception as error:errors.append(error)
        with patch('cq_maintenance.engine.get',return_value=provider),patch('cq_maintenance.engine.signal_bar',side_effect=notify):
            thread=threading.Thread(target=collect);thread.start()
            try:self.assertTrue(published.wait(3));self.assertTrue(thread.is_alive())
            finally:release.set();thread.join(5)
        self.assertFalse(errors)
    def test_failed_check_also_publishes_after_recording_error(self):
        provider=Mock();provider.check.side_effect=RuntimeError('backend')
        with patch('cq_maintenance.engine.get',return_value=provider),patch('cq_maintenance.engine.signal_bar') as notify:
            engine.check_one('test',self.settings.checks['test'])
            notify.assert_called_once_with(12)
            self.assertEqual(engine.previous('test').state,'unknown')
    def test_successful_mail_repair_clears_only_its_own_stale_unit_failure(self):
        from cq_maintenance.providers import mail
        ctx=Context('mail',Check(provider='mail'),checking=False)
        replies=[subprocess.CompletedProcess([],0),subprocess.CompletedProcess([],0,'failed',''),subprocess.CompletedProcess([],0)]
        with patch.object(Context,'run',side_effect=replies) as run:
            mail.execute(ctx,'fix')
        self.assertEqual(run.call_args.args[0],['systemctl','--user','reset-failed','cq-mail.service'])
    def test_mail_repair_immediately_refreshes_dependent_unit_status(self):
        from cq_maintenance.model import Action
        self.settings.checks={'mail':Check(provider='mail'),'units':Check(provider='units')}
        mail=Mock();mail.check.side_effect=lambda ctx:ctx.result('ok','Synced',actions=[Action(id='fix',label='Sync',safe=True)])
        mail.execute.return_value='Completed'
        units=Mock();units.check.side_effect=lambda ctx:ctx.result('ok','No failed units')
        with patch('cq_maintenance.engine.get',side_effect=lambda name:mail if name=='mail' else units):engine.fix(['mail'])
        units.check.assert_called_once()
        self.assertEqual(engine.previous('units').state,'ok')
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
        self.assertEqual(result.state,'pending');self.assertEqual(before,self.git(['rev-parse','HEAD'],self.work))
        self.assertTrue(result.metrics['tracking_setup_required'])
        self.assertIn('tracking setup needed',result.summary)
        self.assertNotIn('↑',result.summary)
    def test_missing_tracking_is_pending_with_local_changes_and_no_fetch(self):
        from cq_maintenance.providers import git
        branch=self.git(['branch','--show-current'],self.work)
        self.git(['config','--unset-all',f'branch.{branch}.remote'],self.work)
        (self.work/'one').write_text('Local change')
        original=Context.run
        def call(ctx,args,**kwargs):
            if 'fetch' in args:raise AssertionError('Do not fetch without safe tracking')
            return original(ctx,args,**kwargs)
        with patch.object(Context,'run',autospec=True,side_effect=call):row=git.check(self.ctx)
        self.assertEqual(row.state,'pending')
        self.assertEqual(row.metrics['dirty'],1)
        self.assertTrue(row.metrics['tracking_setup_required'])
        self.assertNotIn('ahead',row.metrics)
        self.assertTrue(any('no new commit is needed' in line for line in row.details))
        self.assertFalse(any(a.safe for a in row.actions))

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
    def test_manual_upgrade_invalidates_recent_arch_and_aur_results(self):
        from cq_maintenance.providers import packages
        database=self.home/'pacman';(database/'local').mkdir(parents=True)
        for kind in ('arch','aur'):
            configuration=Check(provider='packages',interval=21600,options={'kind':kind,'database_path':str(database)})
            self.settings.checks={'test':configuration}
            old=Result(id='test',state='pending',summary='Updates waiting',metrics={'local_revision':packages.local_revision(configuration.options)})
            engine.save(old)
            with patch.object(packages,'check',side_effect=lambda ctx:ctx.result('ok','Up to date',metrics={'local_revision':packages.local_revision(ctx.options)})) as check:
                engine.collect(due=True);check.assert_not_called()
                # Simulate pacman's replacement of the installed database directory.
                (database/'local').rename(database/('old-'+kind));(database/'local').mkdir()
                engine.collect(due=True);self.assertEqual(check.call_count,1)
                self.assertEqual(engine.previous('test').state,'ok')
                engine.collect(due=True);self.assertEqual(check.call_count,1)
    def test_invalidation_waits_for_running_pacman_transaction(self):
        from cq_maintenance.providers import packages
        database=self.home/'pacman';(database/'local').mkdir(parents=True);(database/'db.lck').touch()
        config=Check(provider='packages',options={'kind':'arch','database_path':str(database)})
        self.assertFalse(packages.invalidated(config,Result(id='test',state='pending',summary='Old')))
        (database/'db.lck').unlink()
        self.assertTrue(packages.invalidated(config,Result(id='test',state='pending',summary='Old')))
    def test_package_count_severity_boundaries_and_overrides(self):
        from cq_maintenance.providers import packages
        for kind,count,override,expected in [
            ('arch',0,None,'ok'),('arch',1,None,'pending'),
            ('arch',19,None,'pending'),('arch',20,None,'error'),('arch',21,None,'error'),
            ('aur',1,None,'pending'),('aur',20,None,'pending'),('aur',100,None,'pending'),
            ('arch',20,0,'pending'),('arch',4,5,'pending'),('arch',5,5,'error'),
        ]:
            with self.subTest(kind=kind,count=count,override=override):
                options={'kind':kind}
                if override is not None:options['error_threshold']=override
                ctx=Context('test',Check(provider='packages',options=options))
                output=''.join(f'pkg-{i} 1 -> 2\n' for i in range(count))
                with patch.object(packages,'helper',return_value='paru'),patch.object(Context,'run',return_value=subprocess.CompletedProcess([],0,output,'')):
                    row=packages.check(ctx)
                self.assertEqual(row.state,expected)
                self.assertEqual(row.metrics['updates'],count)
                self.assertTrue(all(not a.safe for a in row.actions))

    def test_empty_aur_query_exit_one_means_up_to_date(self):
        from cq_maintenance.providers import packages
        for helper in ('paru','yay'):
            ctx=Context('test',Check(provider='packages',options={'kind':'aur'}))
            with patch.object(packages,'helper',return_value=helper),patch.object(Context,'run',return_value=subprocess.CompletedProcess([],1,'','')):
                result=packages.check(ctx)
            self.assertEqual(result.state,'ok');self.assertEqual(result.metrics['updates'],0)
            self.assertEqual(result.actions,[])
    def test_aur_error_is_not_mistaken_for_no_updates(self):
        from cq_maintenance.providers import packages
        for code,out,err in [(1,'','AUR request failed'),(1,'pkg 1 -> 2',''),(2,'','')]:
            ctx=Context('test',Check(provider='packages',options={'kind':'aur'}))
            with patch.object(packages,'helper',return_value='paru'),patch.object(Context,'run',return_value=subprocess.CompletedProcess([],code,out,err)):
                with self.assertRaises(Problem):packages.check(ctx)
    def test_successful_aur_updates_are_still_counted(self):
        from cq_maintenance.providers import packages
        ctx=Context('test',Check(provider='packages',options={'kind':'aur'}))
        with patch.object(packages,'helper',return_value='paru'),patch.object(Context,'run',return_value=subprocess.CompletedProcess([],0,'one 1 -> 2\ntwo 3 -> 4\n','')):
            result=packages.check(ctx)
        self.assertEqual(result.state,'pending');self.assertEqual(result.metrics['updates'],2)
    def test_update_failure_is_not_up_to_date(self):
        from cq_maintenance.providers import packages
        with patch.object(Context,'run',return_value=subprocess.CompletedProcess([],1,'','')):
            with self.assertRaises(Problem):packages.check(Context('test',Check(provider='packages')))


class MailUnlockTests(Isolated):
    def test_expected_unlock_is_pending_even_with_old_or_absent_success(self):
        from datetime import datetime,timezone
        from cq_maintenance.providers import mail
        for component in ('mail','contacts'):
            for success in (None,now()-60,now()-86400):
                with self.subTest(component=component,success=success):
                    stamp=datetime.fromtimestamp(success,timezone.utc).isoformat() if success else None
                    data={component:{'state':'unlock-required','message':'Unlock GPG to resume','last_success':stamp}}
                    ctx=Context(component,Check(provider='mail',options={'component':component}))
                    with patch.object(ctx,'run',side_effect=[subprocess.CompletedProcess([],0,json.dumps(data),''),subprocess.CompletedProcess([],0,'active','')]):
                        row=mail.check(ctx)
                    self.assertEqual(row.state,'pending')
                    self.assertEqual(row.last_success,success)
                    self.assertIn('last attempt needed unlock',row.summary)

    def test_timer_and_real_failures_keep_higher_severity(self):
        from datetime import datetime,timezone
        from cq_maintenance.providers import mail
        for record,timer,expected in [('unlock-required','inactive','warning'),('error','active','error'),('error','inactive','error'),('ok','active','warning')]:
            with self.subTest(record=record,timer=timer):
                data={'mail':{'state':record,'last_success':datetime.fromtimestamp(now()-86400,timezone.utc).isoformat()}}
                ctx=Context('mail',Check(provider='mail'))
                with patch.object(ctx,'run',side_effect=[subprocess.CompletedProcess([],0,json.dumps(data),''),subprocess.CompletedProcess([],0,timer,'')]):
                    self.assertEqual(mail.check(ctx).state,expected)


class MailProgressTests(Isolated):
    def test_live_progress_replaces_cached_failure_without_running_commands(self):
        from datetime import datetime,timezone
        from cq_maintenance.providers import mail
        state=self.home/'mail-state';state.mkdir()
        settings=self.home/'.config/mutt/settings.json';settings.parent.mkdir(parents=True)
        settings.write_text(json.dumps({'state':str(state)}))
        stamp=datetime.fromtimestamp(now(),timezone.utc).isoformat()
        previous=Result(id='mail',state='error',summary='Previous attempt failed',checked_at=now(),metrics={'component':'mail','timer_active':True})
        ctx=Context('mail',Check(provider='mail'),previous)
        for record,expected,activity in [('running','pending','syncing'),('ok','ok',''),('error','error',''),('unlock-required','pending','')]:
            with self.subTest(record=record):
                atomic_json(state/'mail-status.json',{'state':record,'last_attempt':stamp,'last_success':stamp,'message':'Fixture progress'})
                with patch.object(ctx,'run',side_effect=AssertionError('Snapshot must be local-only')):
                    row=mail.overlay(ctx,previous)
                self.assertEqual(row.state,expected)
                self.assertEqual(row.activity,activity)
                self.assertEqual(row.checked_at,previous.checked_at)
                self.assertIn('Fixture progress',row.details)

    def test_running_status_is_pending_until_timeout_not_old_success_warning(self):
        from datetime import datetime,timezone
        from cq_maintenance.providers import mail
        ctx=Context('contacts',Check(provider='mail',options={'component':'contacts'}))
        stamp=lambda seconds:datetime.fromtimestamp(now()-seconds,timezone.utc).isoformat()
        data={'state':'running','last_attempt':stamp(10),'last_success':stamp(86400),'message':'Syncing'}
        row=mail.from_status(ctx,data,True)
        self.assertEqual(row.state,'pending');self.assertEqual(row.activity,'syncing')
        self.assertIn('Syncing',row.summary)
        data['last_attempt']=stamp(2200)
        row=mail.from_status(ctx,data,True)
        self.assertEqual(row.state,'warning');self.assertEqual(row.activity,'')
        self.assertIn('stalled',row.summary)

    def test_unlock_status_describes_last_attempt_not_live_key_state(self):
        from cq_maintenance.providers import mail
        ctx=Context('mail',Check(provider='mail'))
        row=mail.from_status(ctx,{'state':'unlock-required'},True)
        self.assertEqual(row.state,'pending')
        self.assertIn('last attempt needed unlock',row.summary)
        self.assertTrue(any('Refresh only reads status' in s for s in row.details))


class CryptReadinessTests(Isolated):
    def test_unverified_pairs_are_pending_and_real_conflicts_keep_priority(self):
        from cq_maintenance.providers import crypt
        for states,expected in [(['unverified']*3,'pending'),(['unverified','encrypt'],'pending'),(['unverified','conflict'],'warning'),(['unverified','invalid'],'error'),(['ok'],'ok')]:
            with self.subTest(states=states):
                data={'entries':[{'name':str(i)+'.gpg','state':state} for i,state in enumerate(states)],'last_success':None}
                ctx=Context('crypt-sync',Check(provider='crypt'))
                with patch.object(ctx,'run',return_value=subprocess.CompletedProcess([],0,json.dumps(data),'')):
                    row=crypt.check(ctx)
                self.assertEqual(row.state,expected)
                self.assertEqual(row.metrics['counts']['unverified'],states.count('unverified'))
                if 'unverified' in states:self.assertTrue(any('Verification pending on this machine' in line for line in row.details))
