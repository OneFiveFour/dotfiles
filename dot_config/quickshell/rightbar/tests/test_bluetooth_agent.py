"""Pairing responses are tested without contacting or changing Bluetooth devices."""
import sys
from pathlib import Path
import unittest
from unittest.mock import Mock
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'backend'))
from bluetooth_agent import BluetoothAgent

class PairingResponses(unittest.TestCase):
    def agent(self,method):
        agent=object.__new__(BluetoothAgent)
        call=Mock()
        agent.pending=(method,call)
        agent.emit=Mock()
        return agent,call

    def test_confirmation_acceptance(self):
        agent,call=self.agent('RequestConfirmation')
        agent.respond({'accept':True})
        call.return_value.assert_called_once_with(None)
        self.assertIsNone(agent.pending)

    def test_rejection_is_reported_to_bluez(self):
        agent,call=self.agent('RequestAuthorization')
        agent.respond({'accept':False})
        call.return_dbus_error.assert_called_once_with('org.bluez.Error.Rejected','Rejected by user')

    def test_invalid_passkey_does_not_accept_or_discard_request(self):
        agent,call=self.agent('RequestPasskey')
        with self.assertRaises(ValueError):
            agent.respond({'accept':True,'value':'not-a-number'})
        call.return_value.assert_not_called()
        self.assertIsNotNone(agent.pending)

    def test_valid_passkey(self):
        agent,call=self.agent('RequestPasskey')
        agent.respond({'accept':True,'value':'001234'})
        self.assertEqual(call.return_value.call_args.args[0].unpack(),(1234,))

if __name__=='__main__':
    unittest.main()
