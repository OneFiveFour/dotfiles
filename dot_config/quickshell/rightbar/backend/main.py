#!/usr/bin/env python3
"""JSON bridge between the QML interface and application/system operations."""
import json
import os
import subprocess
import sys
from gi.repository import GLib
from applications import apps
from battery_status import read_reports
from bluetooth_agent import BluetoothAgent
from process_actions import terminate_app


def emit(kind, **values):
    print(json.dumps({'kind': kind, **values}, ensure_ascii=False), flush=True)


class Backend:
    def __init__(self):
        self.buffer = b''
        self.loop = GLib.MainLoop()
        self.bluetooth = BluetoothAgent(emit)
        os.set_blocking(sys.stdin.fileno(), False)
        GLib.io_add_watch(sys.stdin, GLib.IO_IN | GLib.IO_HUP, self.receive)
        GLib.timeout_add_seconds(5, self.refresh)
        self.refresh()

    def refresh(self):
        try:
            emit('apps', apps=[dict(name=n, pid=p, start=s, state=t) for n,p,s,t in apps()])
            emit('battery', reports=read_reports())
        except Exception as error:
            emit('error', text=str(error))
        return True

    def command(self, data):
        action = data.get('action')
        if action == 'refresh':
            self.refresh()
        elif action == 'terminate':
            terminate_app(data['pid'], data['start'], bool(data.get('force')))
            GLib.timeout_add(500, lambda: (self.refresh(), False)[1])
        elif action == 'lock':
            subprocess.Popen(['loginctl', 'lock-session', os.environ['XDG_SESSION_ID']])
        elif action == 'poweroff':
            subprocess.Popen(['systemctl', 'poweroff'])
        elif action == 'logout':
            subprocess.Popen(['hyprctl', 'dispatch', 'hl.dsp.exit()'])
        elif action == 'pair-response':
            self.bluetooth.respond(data)

    def receive(self, channel, condition):
        if condition & GLib.IO_HUP:
            self.bluetooth.cancel_pending()
            self.loop.quit()
            return False
        try:
            block = os.read(sys.stdin.fileno(), 65536)
            if not block:
                self.loop.quit()
                return False
            self.buffer += block
            while b'\n' in self.buffer:
                line, self.buffer = self.buffer.split(b'\n', 1)
                try:
                    self.command(json.loads(line))
                except Exception as error:
                    emit('error', text=str(error))
        except BlockingIOError:
            pass
        return True


if __name__ == '__main__':
    Backend().loop.run()
