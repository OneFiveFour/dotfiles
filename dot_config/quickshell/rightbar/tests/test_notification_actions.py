"""Notification routing without launching apps or moving real windows."""
import sys
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'backend'))
import notification_actions as actions


def app(identifier='mail.desktop', name='Mail', wm_class='Mail', executable='mail'):
    result = Mock(spec=actions.Gio.DesktopAppInfo)
    result.get_id.return_value = identifier
    result.get_name.return_value = name
    result.get_display_name.return_value = name
    result.get_startup_wm_class.return_value = wm_class
    result.get_executable.return_value = executable
    return result


class NotificationRouting(unittest.TestCase):
    def test_desktop_id_beats_display_name(self):
        browser, mail = app('browser.desktop', 'Browser'), app()
        self.assertIs(actions.resolve_app({'desktopEntry': 'browser', 'appName': 'Mail'},
                                         [browser, mail]), browser)

    def test_tuta_name_resolves_appimage_desktop_entry(self):
        tuta = app('tutanota-desktop-linux.desktop', 'Tuta', 'Tuta', '/tmp/tuta.AppImage')
        self.assertIs(actions.resolve_app({'appName': 'Tuta'}, [tuta]), tuta)

    def test_browser_icon_identifies_web_notification(self):
        browser = app('firefox.desktop', 'Firefox', 'firefox', 'firefox')
        self.assertIs(actions.resolve_app({'appName': 'WhatsApp', 'appIcon': 'firefox'},
                                         [browser]), browser)

    def test_ambiguous_or_partial_names_are_not_launched(self):
        self.assertIsNone(actions.resolve_app({'appName': 'Mail'}, [app(), app('other.desktop')]))
        self.assertIsNone(actions.resolve_app({'appName': 'Mai'}, [app()]))
        self.assertNotIn('electron', actions.app_keys(app(executable='electron')))

    def test_focus_most_recent_matching_window(self):
        windows = [dict(address='0x1', initialClass='Mail', focusHistoryID=3),
                   dict(address='0x2', **{'class': 'mail'}, focusHistoryID=1),
                   dict(address='0x3', **{'class': 'mail'}, mapped=False, focusHistoryID=0)]
        self.assertEqual(actions.matching_window({}, app(), windows)['address'], '0x2')

    def test_appimage_origin_class_survives_desktop_file_resolution(self):
        tuta = app('tutanota-desktop-linux.desktop', 'Tuta', 'Tuta')
        window = {'class': 'tutanota-desktop', 'address': '0x42'}
        self.assertIs(actions.matching_window({'desktopEntry': 'tutanota-desktop'},
                                             tuta, [window]), window)

    @patch.object(actions.subprocess, 'run')
    @patch.object(actions.Gio.AppInfo, 'get_all', return_value=[])
    def test_native_action_never_launches_a_second_instance(self, get_all, run):
        run.return_value = Mock(returncode=0, stdout='[]')
        actions.open_notification({'appName': 'Unknown'}, launch=False)
        self.assertEqual(run.call_count, 1)

    @patch.object(actions.subprocess, 'run')
    @patch.object(actions.Gio.AppInfo, 'get_all', return_value=[])
    def test_unknown_origin_reports_missing_fallback(self, get_all, run):
        run.return_value = Mock(returncode=0, stdout='[]')
        with self.assertRaisesRegex(RuntimeError, 'App-Zuordnung'):
            actions.open_notification({'appName': 'Unknown'}, launch=True)

    @patch.object(actions.subprocess, 'run')
    @patch.object(actions.Gio.AppInfo, 'get_all')
    def test_fallback_launches_resolved_app(self, get_all, run):
        mail = app()
        get_all.return_value = [mail]
        run.return_value = Mock(returncode=0, stdout='[]')
        actions.open_notification({'desktopEntry': 'mail'}, launch=True)
        mail.launch.assert_called_once_with([], None)

    @patch.object(actions.subprocess, 'run')
    @patch.object(actions.Gio.AppInfo, 'get_all')
    def test_existing_window_is_focused_without_launch(self, get_all, run):
        mail = app()
        get_all.return_value = [mail]
        run.side_effect = [Mock(returncode=0, stdout='[{"class":"Mail","address":"0xab"}]'), Mock()]
        actions.open_notification({'desktopEntry': 'mail'}, launch=True)
        mail.launch.assert_not_called()
        self.assertEqual(run.call_args.args[0], ['hyprctl', 'eval',
            'hl.dispatch(hl.dsp.focus({window = "address:0xab"}))'])


if __name__ == '__main__':
    unittest.main()
