"""BlueZ pairing agent: PIN entry, confirmation and authorization."""
import time
from gi.repository import Gio, GLib

AGENT_XML = '''<node><interface name="org.bluez.Agent1">
<method name="Release"/>
<method name="RequestPinCode"><arg type="o" direction="in"/><arg type="s" direction="out"/></method>
<method name="DisplayPinCode"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
<method name="RequestPasskey"><arg type="o" direction="in"/><arg type="u" direction="out"/></method>
<method name="DisplayPasskey"><arg type="o" direction="in"/><arg type="u" direction="in"/><arg type="q" direction="in"/></method>
<method name="RequestConfirmation"><arg type="o" direction="in"/><arg type="u" direction="in"/></method>
<method name="RequestAuthorization"><arg type="o" direction="in"/></method>
<method name="AuthorizeService"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
<method name="Cancel"/>
</interface></node>'''


class BluetoothAgent:
    def __init__(self, emit):
        self.emit = emit
        self.pending = None
        self.pending_since = 0
        self.bus = None
        self.info = Gio.DBusNodeInfo.new_for_xml(AGENT_XML)
        try:
            self.bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
            self.bus.register_object('/org/florian/RightbarAgent', self.info.interfaces[0], self.agent, None, None)
            self.register_agent()
        except GLib.Error as error:
            self.emit('error', text='Bluetooth-Agent: ' + error.message)
        GLib.timeout_add_seconds(5, self.expire_request)

    def register_agent(self):
        def registered(bus, result):
            try:
                bus.call_finish(result)
                bus.call('org.bluez', '/org/bluez', 'org.bluez.AgentManager1', 'RequestDefaultAgent', GLib.Variant('(o)', ('/org/florian/RightbarAgent',)), None, Gio.DBusCallFlags.NONE, 5000, None, defaulted)
            except GLib.Error as e:
                self.emit('error', text='Bluetooth-Agent: ' + e.message)
        def defaulted(bus, result):
            try:
                bus.call_finish(result)
                self.emit('agent-ready')
            except GLib.Error as e:
                self.emit('error', text='Bluetooth-Agent: ' + e.message)
        self.bus.call('org.bluez', '/org/bluez', 'org.bluez.AgentManager1', 'RegisterAgent', GLib.Variant('(os)', ('/org/florian/RightbarAgent', 'KeyboardDisplay')), None, Gio.DBusCallFlags.NONE, 5000, None, registered)

    def cancel_pending(self):
        if self.pending:
            self.pending[1].return_dbus_error('org.bluez.Error.Canceled', 'Canceled')
            self.pending = None
        self.emit('pair-clear')

    def agent(self, connection, sender, path, interface, method, params, invocation):
        args = params.unpack()
        if method in ('Cancel', 'Release'):
            self.cancel_pending()
            invocation.return_value(None)
        elif method in ('DisplayPinCode', 'DisplayPasskey'):
            code = args[1] if method == 'DisplayPinCode' else f'{args[1]:06d}'
            self.emit('pair', mode='display', text=f'Code am Gerät eingeben: {code}', device=args[0])
            invocation.return_value(None)
        else:
            self.cancel_pending()
            self.pending = (method, invocation)
            self.pending_since = time.monotonic()
            mode = 'pin' if method == 'RequestPinCode' else 'passkey' if method == 'RequestPasskey' else 'confirm'
            text = f'Code {args[1]:06d} auf beiden Geräten gleich?' if method == 'RequestConfirmation' else 'Bluetooth-Verbindung erlauben?'
            if mode in ('pin', 'passkey'):
                text = 'Kopplungscode des Geräts eingeben'
            self.emit('pair', mode=mode, text=text, device=args[0])

    def expire_request(self):
        if self.pending and time.monotonic() - self.pending_since > 90:
            self.cancel_pending()
        return True

    def respond(self, data):
        if not self.pending:
            return
        method, call = self.pending
        if not data.get('accept'):
            call.return_dbus_error('org.bluez.Error.Rejected', 'Rejected by user')
        elif method == 'RequestPinCode':
            value = str(data.get('value', ''))
            if not 1 <= len(value) <= 16:
                raise ValueError('Bitte einen gültigen PIN eingeben.')
            call.return_value(GLib.Variant('(s)', (value,)))
        elif method == 'RequestPasskey':
            value = str(data.get('value', ''))
            if not value.isdigit() or not 0 <= int(value) <= 999999:
                raise ValueError('Bitte einen sechsstelligen Zahlencode eingeben.')
            call.return_value(GLib.Variant('(u)', (int(value),)))
        else:
            call.return_value(None)
        self.pending = None
        self.emit('pair-clear')
