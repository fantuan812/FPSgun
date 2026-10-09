"""Pure Python authoring preflight tests; never imports Unreal or touches assets."""
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'Scripts'))
from AssemblyAssetNames import output_names


class AssetNamesTest(unittest.TestCase):
    def test_distinct_names(self):
        self.assertEqual(output_names(['kite01.core', 'shared.adapter.universal_micro']),
                         {'kite01.core':'kite01_core', 'shared.adapter.universal_micro':'shared_adapter_universal_micro'})

    def test_dot_underscore_collision(self):
        with self.assertRaises(ValueError):
            output_names(['a.b', 'a_b'])

    def test_dash_underscore_collision(self):
        with self.assertRaises(ValueError):
            output_names(['a-b', 'a_b'])

    def test_duplicate_id(self):
        with self.assertRaises(ValueError):
            output_names(['a.b', 'a.b'])

    def test_invalid_ids(self):
        for value in ('', 'A.b', '../a', 'a/b', 'a\\b', 'a b', '武器', 'a\0b', 'a'*97, 42):
            with self.subTest(value=value), self.assertRaises(ValueError):
                output_names([value])

    def test_reserved_catalog_name(self):
        with self.assertRaises(ValueError):
            output_names(["assemblycatalog"])

    def test_exact_length_limit(self):
        value = 'a'*96
        self.assertEqual(output_names([value]), {value:value})


if __name__ == '__main__':
    unittest.main()
