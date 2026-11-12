"""Identity-checked termination of user desktop applications."""
import os
import signal
from pathlib import Path
from applications import apps

def terminate_app(pid, start, force=False):
    pid = int(pid)
    if not any(p == pid and s == str(start) for _, p, s, _ in apps()):
        raise ValueError('Diese App läuft nicht mehr oder wurde inzwischen neu gestartet.')
    fd = os.pidfd_open(pid)
    try:
        p = Path(f'/proc/{pid}')
        current = p.joinpath('stat').read_text().rsplit(')', 1)[1].split()[19]
        if current != str(start) or p.stat().st_uid != os.getuid():
            raise ValueError('Die App wurde inzwischen neu gestartet.')
        signal.pidfd_send_signal(fd, signal.SIGKILL if force else signal.SIGTERM)
    finally:
        os.close(fd)

