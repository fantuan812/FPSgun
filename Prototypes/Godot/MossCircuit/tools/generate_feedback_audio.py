#!/usr/bin/env python3
"""Generate MossCircuit's two original procedural cues; standard library only.

Canonical checked-in bytes are authoritative. Reproduction is exact in the
recorded toolchain, not a cross-platform libm bit-identity guarantee.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import platform
import struct
import sys

RATE = 44100
CUES = {
    "player_damage": (7056, 320, 140, 0.25),
    "shield_block": (5292, 720, 1080, 0.15),
}


def make_cue(count, f0, f1, harmonic):
    duration = (count - 1) / RATE
    envelope, raw = [], []
    for n in range(count):
        t = n / RATE
        phase = 2 * math.pi * (f0 * t + (f1 - f0) * t * t / (2 * duration))
        env = math.sin(math.pi * min(1, n / 221) / 2) ** 2
        env *= math.sin(math.pi * min(1, (count - 1 - n) / 662) / 2) ** 2
        envelope.append(env)
        raw.append(env * (math.sin(phase) + harmonic * math.sin(2 * phase)))
    dc = sum(raw) / sum(envelope)
    corrected = [x - e * dc for x, e in zip(raw, envelope)]
    scale = 0.25 / max(abs(x) for x in corrected)
    samples = [max(-32768, min(32767, round(32767 * x * scale))) for x in corrected]
    pcm = struct.pack("<" + "h" * count, *samples)
    header = struct.pack("<4sI4s4sIHHIIHH4sI", b"RIFF", 36 + len(pcm), b"WAVE",
                         b"fmt ", 16, 1, 1, RATE, RATE * 2, 2, 16, b"data", len(pcm))
    values = [x / 32768 for x in samples]
    return header + pcm, {
        "samples": count, "seconds": count / RATE, "rate": RATE,
        "channels": 1, "bits": 16, "f0": f0, "f1": f1, "harmonic": harmonic,
        "pcm_sha256": hashlib.sha256(pcm).hexdigest(),
        "peak": max(abs(x) for x in values),
        "rms": math.sqrt(sum(x * x for x in values) / count),
        "mean": sum(values) / count, "first": samples[0], "last": samples[-1],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "assets/audio")
    parser.add_argument("--provenance", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    report = {"origin": "Original deterministic procedural non-voice synthesis for MossCircuit v35; no external audio inputs.",
              "scope": "Two finite player feedback cues; no new license waiver or third-party licensing claim.",
              "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "python": sys.version.split()[0], "implementation": platform.python_implementation(),
              "reproducibility": "Canonical WAV bytes and pinned toolchain; cross-platform libm identity not asserted.", "cues": {}}
    for cue, params in CUES.items():
        wav, metadata = make_cue(*params)
        (args.output / (cue + ".wav")).write_bytes(wav)
        metadata.update(bytes=len(wav), wav_sha256=hashlib.sha256(wav).hexdigest())
        report["cues"][cue] = metadata
    target = args.provenance or args.output / "provenance.json"
    target.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
