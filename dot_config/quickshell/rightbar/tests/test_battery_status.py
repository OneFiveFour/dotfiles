"""Run with: python3 -m unittest discover -s tests -v"""
import sys
from pathlib import Path
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'backend'))
from battery_status import classify

class BatteryLevels(unittest.TestCase):
    def test_percentage_boundaries(self):
        for value,bars in [(0,1),(14.9,1),(15,2),(79.9,2),(80,3),(100,3)]:
            self.assertEqual(classify({'BatteryLevel':1,'Percentage':value})['bars'],bars)

    def test_coarse_value_overrides_conflicting_percentage(self):
        report=classify({'BatteryLevel':6,'Percentage':100})
        self.assertEqual(report['bars'],2)
        self.assertTrue(report['coarse'])

    def test_coarse_empty_and_full(self):
        self.assertEqual(classify({'BatteryLevel':3})['bars'],1)
        self.assertEqual(classify({'BatteryLevel':8})['bars'],3)

    def test_unknown_or_invalid_is_not_assumed_full(self):
        self.assertIsNone(classify({'BatteryLevel':0,'Percentage':100}))
        self.assertIsNone(classify({'BatteryLevel':1,'Percentage':-1}))

if __name__=='__main__':
    unittest.main()
