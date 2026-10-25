"""Offline negative checks: export helpers must fail closed without overwriting.

No template download or engine execution is performed by these fixtures.
"""
from pathlib import Path
import json
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ExportToolSafety(unittest.TestCase):
    def invoke(self, script, *args):
        return subprocess.run([sys.executable, str(ROOT / 'tools' / script), *map(str, args)], capture_output=True, text=True, timeout=20)

    def test_existing_output_is_not_modified(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'existing'; output.mkdir()
            marker = output / 'keep.txt'; marker.write_text('keep this exact content')
            result = self.invoke('build_desktop.py', '--project', ROOT, '--templates', Path(directory) / 'absent', '--output', output)
            self.assertEqual(result.returncode, 2)
            self.assertIn('Output already exists', result.stderr)
            self.assertEqual(marker.read_text(), 'keep this exact content')
            self.assertEqual(list(output.iterdir()), [marker])

    def test_missing_templates_do_not_start_build(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'not-created'
            result = self.invoke('build_desktop.py', '--project', ROOT, '--templates', Path(directory) / 'absent', '--output', output)
            self.assertEqual(result.returncode, 2)
            self.assertIn('Template missing or checksum mismatch', result.stderr)
            self.assertFalse(output.exists())

    def test_corrupt_cached_archive_is_not_extracted(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            manifest = json.loads((ROOT / 'tools/godot_templates.json').read_text())
            archive = output / manifest['archive_name']; archive.write_bytes(b'not an official archive')
            result = self.invoke('fetch_export_templates.py', '--output', output)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('does not match pinned official release', result.stderr)
            self.assertEqual(archive.read_bytes(), b'not an official archive')
            self.assertFalse((output / manifest['version']).exists())


if __name__ == '__main__':
    unittest.main()
