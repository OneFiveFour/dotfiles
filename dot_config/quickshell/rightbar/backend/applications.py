#!/usr/bin/env python3
"""Recognise user desktop applications while excluding session infrastructure."""
import configparser
import datetime
import json
import os
from pathlib import Path
import shlex
import signal
import subprocess
import sys


def run(args, **kw):
    return subprocess.run(args, text=True, capture_output=True, **kw)


def apps():
    # Recognise desktop applications, not session infrastructure or arbitrary services.
    executables = {}
    for folder in [Path('/usr/share/applications'), Path('/usr/local/share/applications'),
                   Path.home()/'.local/share/applications', Path('/var/lib/flatpak/exports/share/applications'),
                   Path.home()/'.local/share/flatpak/exports/share/applications']:
        for desktop in folder.glob('*.desktop'):
            try:
                c = configparser.ConfigParser(interpolation=None, strict=False)
                c.read(desktop)
                entry = c['Desktop Entry']
                if entry.getboolean('NoDisplay', False) or entry.getboolean('Hidden', False):
                    continue
                cmd = shlex.split(entry.get('Exec', ''))
                if cmd and Path(cmd[0]).name not in ('env', 'sh', 'bash', 'flatpak'):
                    executables[Path(cmd[0]).name] = entry.get('Name', Path(cmd[0]).name)
            except (ValueError, KeyError, configparser.Error):
                pass
    clients = json.loads(run(['hyprctl', '-j', 'clients'], timeout=3).stdout or '[]')
    windows = {int(c['pid']): c.get('class', 'App') for c in clients}
    found = []
    excluded = {'waybar', 'rofi', 'swaync', 'hypridle', 'hyprpaper', 'hyprlock', 'Hyprland', 'Xwayland', 'zenity', 'quickshell', 'qs'}
    for p in Path('/proc').iterdir():
        if not p.name.isdigit():
            continue
        try:
            if p.stat().st_uid != os.getuid():
                continue
            exe = (p/'exe').resolve().name
            pid = int(p.name)
            argv = (p/'cmdline').read_bytes().split(b'\0')
            if exe in excluded or any(x.startswith(b'--type=') for x in argv):
                continue
            if exe not in executables and pid not in windows:
                continue
            # Avoid matching desktop entries against unrelated headless processes.
            env = (p/'environ').read_bytes()
            if pid not in windows and b'DISPLAY=' not in env:
                continue
            name = executables.get(exe, windows.get(pid, exe))
            start = (p/'stat').read_text().rsplit(')', 1)[1].split()[19]
            found.append((name, pid, start, 'Fenster' if pid in windows else 'Hintergrund'))
        except (OSError, ValueError, IndexError):
            continue
    return sorted(found, key=lambda a: (a[0].lower(), a[1]))

