import os,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
from test_engine import Isolated
from cq_maintenance.providers import syncthing
from cq_maintenance.providers.base import Context
from cq_maintenance.model import Check

class SyncthingTests(Isolated):
    def setUp(self):
        super().setUp();self.folder=self.home/'folder';self.folder.mkdir();self.ctx=Context('test',Check(provider='syncthing'))
        self.responses={'system/status':{},'config/folders':[{'id':'f','label':'Folder','path':str(self.folder)}],'system/connections':{'connections':{'peer':{'connected':True}}},'db/completion':{'needItems':0},'db/status':{'state':'idle','pullErrors':0}}
    def check(self):
        client=type('Fake',(),{'request':lambda _,endpoint,*args,**kw:self.responses[endpoint]})()
        with patch.object(syncthing,'Client',return_value=client):return syncthing.check(self.ctx)
    def test_idle_healthy_without_recent_transfers(self):self.assertEqual(self.check().state,'ok')
    def test_offline_is_unknown_not_false_green(self):
        self.responses['system/connections']={'connections':{}}
        self.assertEqual(self.check().state,'unknown')
    def test_folder_error_and_conflict_names_are_detected(self):
        self.responses['db/status']['pullErrors']=1
        (self.folder/'document.sync-conflict-20260101.txt').write_text('do not read')
        result=self.check();self.assertEqual(result.state,'error');self.assertEqual(result.metrics['conflicts'],1)
    def test_scan_does_not_follow_symlink(self):
        outside=self.home/'outside';outside.mkdir();(outside/'x.sync-conflict-test').touch()
        (self.folder/'link').symlink_to(outside)
        self.assertEqual(self.check().metrics['conflicts'],0)
    def test_api_key_not_in_error(self):
        with patch.object(syncthing,'Client',side_effect=syncthing.Problem('API unavailable')):result=syncthing.check(self.ctx)
        self.assertEqual(result.state,'error')

    def test_slow_scan_has_separate_action_timeout(self):
        config=self.home/'syncthing.xml';config.write_text('<configuration><gui><address>127.0.0.1:8384</address><apikey>secret</apikey></gui></configuration>')
        ctx=Context('test',Check(provider='syncthing',timeout=30,options={'config':str(config)}),checking=False)
        client=syncthing.Client(ctx)
        with patch.object(syncthing.urllib.request,'urlopen',side_effect=TimeoutError('secret')) as request:
            with self.assertRaisesRegex(syncthing.Problem,'scan may still be running'):client.request('db/scan','POST',folder='f')
        self.assertGreater(request.call_args.kwargs['timeout'],30)
    def test_failed_scan_does_not_skip_remaining_folders(self):
        from unittest.mock import Mock
        client=Mock();client.request.side_effect=[[{'id':'a','label':'First'},{'id':'b'},{'id':'paused','paused':True}],syncthing.Problem('timed out'),{}]
        with patch.object(syncthing,'Client',return_value=client):
            with self.assertRaisesRegex(syncthing.Problem,'1 folder scans completed; First: timed out'):syncthing.execute(self.ctx,'fix')
        self.assertEqual(client.request.call_args_list[-1].kwargs,{'folder':'b'})

    def test_send_only_remote_changes_require_review(self):
        self.responses['config/folders'][0]['type']='sendonly'
        self.responses['db/status']['needTotalItems']=14
        self.responses['db/completion']['needItems']=14
        result=self.check()
        self.assertIn('send-only; review before overriding',result.details[0])
        self.assertEqual(result.activity,'')
        self.assertNotIn('override',[action.id for action in result.actions])
