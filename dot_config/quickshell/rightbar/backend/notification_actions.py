"""Resolve notification origins using installed desktop entries; focus or launch them."""
import json
from pathlib import Path
import re
import subprocess
from gi.repository import Gio


def normalized(value):
    return str(value or '').removesuffix('.desktop').casefold()


def app_keys(app):
    keys = {normalized(app.get_id()), normalized(app.get_name()),
            normalized(app.get_display_name()), normalized(app.get_startup_wm_class())}
    executable = Path(app.get_executable() or '').name
    if executable not in {'env', 'flatpak', 'sh', 'bash', 'python', 'python3', 'electron', 'java'}:
        keys.add(normalized(executable))
    return keys - {''}


def resolve_app(source, apps):
    desktop = normalized(source.get('desktopEntry'))
    if desktop:
        match = next((app for app in apps if normalized(app.get_id()) == desktop), None)
        if match:
            return match
    # Exact, unambiguous matches only. Never execute commands or URLs from message text.
    for value in (source.get('appName'), source.get('appIcon')):
        key = normalized(value)
        matches = [app for app in apps if key and key in app_keys(app)]
        if len(matches) == 1:
            return matches[0]
    return None


def matching_window(source, app, windows):
    # AppImages may report a desktop ID/window class different from their installed
    # desktop filename and StartupWMClass. Preserve the original identifiers too.
    keys = {normalized(source.get('desktopEntry')), normalized(source.get('appName'))}
    if app:
        keys.update(app_keys(app))
    keys.discard('')
    matches = [w for w in windows if w.get('mapped', True) and keys.intersection(
        normalized(w.get(k)) for k in ('class', 'initialClass'))]
    return min(matches, key=lambda w: w.get('focusHistoryID', 999999)) if matches else None


def open_notification(source, launch=False):
    apps = Gio.AppInfo.get_all()
    # Only DesktopAppInfo has startup WM class metadata.
    app = resolve_app(source, [a for a in apps if isinstance(a, Gio.DesktopAppInfo)])
    result = subprocess.run(['hyprctl', '-j', 'clients'], capture_output=True, text=True, timeout=5)
    if result.returncode:
        raise RuntimeError('App-Fenster konnten nicht ermittelt werden.')
    window = matching_window(source, app, json.loads(result.stdout))
    if window:
        address = window.get('address', '')
        if not re.fullmatch(r'0x[0-9a-fA-F]+', address):
            raise ValueError('Ungültige Fensteradresse')
        code = 'hl.dispatch(hl.dsp.focus({window = ' + json.dumps('address:' + address) + '}))'
        subprocess.run(['hyprctl', 'eval', code], check=True, capture_output=True, timeout=5)
    elif launch and app:
        app.launch([], None)
    elif launch:
        raise RuntimeError('Dieser Benachrichtigung fehlen eine Öffnen-Aktion und eine eindeutige App-Zuordnung.')
