"""Inspect canonical RIFF bytes and local deterministic provenance (no engine)."""
import hashlib
import json
import math
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class FeedbackPCM(unittest.TestCase):
    def test_canonical_pcm(self):
        provenance = json.loads((ROOT / "assets/audio/provenance.json").read_text())
        identities, total = [], 0
        for cue, count in (("player_damage", 7056), ("shield_block", 5292)):
            wav = (ROOT / f"assets/audio/{cue}.wav").read_bytes()
            total += len(wav)
            header = struct.unpack("<4sI4s4sIHHIIHH4sI", wav[:44])
            self.assertEqual(header, (b"RIFF", len(wav) - 8, b"WAVE", b"fmt ", 16, 1, 1, 44100, 88200, 2, 16, b"data", count * 2))
            samples = struct.unpack("<" + "h" * count, wav[44:])
            values = [x / 32768 for x in samples]
            self.assertEqual((samples[0], samples[-1]), (0, 0))
            self.assertLessEqual(max(map(abs, values)), .25)
            self.assertLessEqual(abs(sum(values) / count), .001)
            rms = math.sqrt(sum(x*x for x in values) / count)
            self.assertGreaterEqual(rms, .02)
            self.assertLessEqual(rms, .18)
            self.assertTrue(all(math.isfinite(x) for x in values))
            self.assertEqual(hashlib.sha256(wav).hexdigest(), provenance["cues"][cue]["wav_sha256"])
            identities.append(hashlib.sha256(wav[44:]).hexdigest())
        self.assertLessEqual(total, 32768)
        self.assertNotEqual(*identities)

    def test_pinned_local_regeneration(self):
        script = ROOT / "tools/generate_feedback_audio.py"
        recorded = json.loads((ROOT / "assets/audio/provenance.json").read_text())
        self.assertEqual(hashlib.sha256(script.read_bytes()).hexdigest(), recorded["generator_sha256"])
        with tempfile.TemporaryDirectory() as tmp:
            subprocess.run([sys.executable, str(script), "--output", tmp], check=True, capture_output=True)
            for cue in ("player_damage", "shield_block"):
                self.assertEqual((Path(tmp) / f"{cue}.wav").read_bytes(), (ROOT / f"assets/audio/{cue}.wav").read_bytes())


if __name__ == "__main__":
    unittest.main()
