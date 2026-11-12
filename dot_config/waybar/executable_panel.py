#!/usr/bin/env python3
"""Waybar actions; appearance lives in config.jsonc and style.css."""
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


def menu(title, rows):
    result = run(['rofi', '-dmenu', '-i', '-no-custom', '-format', 'i', '-p', title,
                  '-theme-str', 'window { width: 560px; }'], input='\n'.join(rows))
    return int(result.stdout.strip()) if result.returncode == 0 and result.stdout.strip().isdigit() else None


def confirm(text):
    return menu(text, ['Abbrechen', 'Bestätigen']) == 1


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
    excluded = {'waybar', 'rofi', 'swaync', 'hypridle', 'hyprpaper', 'hyprlock', 'Hyprland', 'Xwayland', 'zenity'}
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


def main():
    action = sys.argv[1]
    if action == 'clock':
        now = datetime.datetime.now()
        month = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'][now.month-1]
        print(json.dumps({'text': f'{now.day}. {month}\n{now:%H:%M}', 'tooltip': 'Kalender öffnen'}))
    elif action == 'calendar':
        subprocess.run(['zenity', '--calendar', '--title=Kalender', '--text=Datum auswählen', '--width=360'], env={**os.environ, 'LC_TIME': 'de_DE.UTF-8'})
    elif action == 'power':
        choice = menu('Sitzung', ['⏻  Ausschalten', '⏻  Abmelden'])
        if choice == 0 and confirm('Computer ausschalten?'):
            subprocess.run(['systemctl', 'poweroff'])
        elif choice == 1 and confirm('Von Hyprland abmelden?'):
            subprocess.run(['hyprctl', 'dispatch', 'hl.dsp.exit()'])
    elif action == 'bluetooth':
        subprocess.run(['gnome-control-center', 'bluetooth'], env={**os.environ, 'XDG_CURRENT_DESKTOP': 'GNOME'})
    elif action in ('apps', 'apps-status'):
        found = apps()
        if action == 'apps-status':
            print(json.dumps({'text': '', 'tooltip': f'{len(found)} laufende Apps – anzeigen und beenden'}))
            return
        if not found:
            menu('Laufende Apps', ['Keine erkannten Apps'])
            return
        choice = menu('Laufende Apps', [f'{name} · {state} · PID {pid}' for name, pid, start, state in found])
        if choice is None or choice >= len(found):
            return
        name, pid, start, state = found[choice]
        mode = menu(name, ['Abbrechen', 'App beenden', 'Beenden erzwingen'])
        if mode not in (1, 2) or not confirm(f'{name} ' + ('beenden?' if mode == 1 else 'zwangsweise beenden? Ungespeicherte Daten gehen verloren.')):
            return
        # Check process identity again before signalling, and hold a pidfd against reuse.
        try:
            fd = os.pidfd_open(pid)
            try:
                current = Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()[19]
                if current == start and Path(f'/proc/{pid}').stat().st_uid == os.getuid():
                    signal.pidfd_send_signal(fd, signal.SIGTERM if mode == 1 else signal.SIGKILL)
            finally:
                os.close(fd)
        except (OSError, ProcessLookupError):
            pass

if __name__ == '__main__':
    main()
