"""Read UPower battery levels; prefer explicit coarse levels over percentages."""
from gi.repository import Gio, GLib

COARSE_LEVELS = {3: (1, 'Niedrig'), 4: (1, 'Kritisch'),
                 6: (2, 'Normal'), 7: (3, 'Hoch'), 8: (3, 'Voll')}


def classify(properties):
    level = int(properties.get('BatteryLevel', 0))
    if level in COARSE_LEVELS:
        bars, label = COARSE_LEVELS[level]
        return {'bars': bars, 'label': label, 'coarse': True, 'source': 'UPower'}
    # BatteryLevel=None means that an actual percentage is available.
    if level == 1:
        percentage = float(properties.get('Percentage', -1))
        if 0 <= percentage <= 100:
            bars = 1 if percentage < 15 else 2 if percentage < 80 else 3
            return {'bars': bars, 'label': f'{percentage:.0f} %',
                    'coarse': False, 'source': 'UPower'}
    return None


def read_reports():
    reports = {}
    try:
        bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
        paths = bus.call_sync('org.freedesktop.UPower', '/org/freedesktop/UPower',
            'org.freedesktop.UPower', 'EnumerateDevices', None,
            GLib.VariantType.new('(ao)'), Gio.DBusCallFlags.NONE, 2000, None).unpack()[0]
        for path in paths:
            props = bus.call_sync('org.freedesktop.UPower', path,
                'org.freedesktop.DBus.Properties', 'GetAll',
                GLib.Variant('(s)', ('org.freedesktop.UPower.Device',)),
                GLib.VariantType.new('(a{sv})'), Gio.DBusCallFlags.NONE, 2000, None).unpack()[0]
            if not props.get('IsPresent'):
                continue
            report = classify(props)
            if report is None:
                continue
            serial = str(props.get('Serial', '')).strip().lower()
            model = str(props.get('Model', '')).strip().lower()
            if serial:
                reports[serial] = report
            if model:
                reports['name:' + model] = report
    except GLib.Error:
        # Quickshell can still use BlueZ when UPower has no matching information.
        pass
    return reports
