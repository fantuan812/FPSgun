"""Run standalone Godot checks with explicit success markers and input hashes.

Logs and writable HOME/XDG directories must live outside the project. A fresh
source extraction gives a cold import; headless checks are not GUI acceptance.
"""
import argparse
import hashlib
import json
import os
import pathlib
import re
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--project", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parents[1])
parser.add_argument("--output", type=pathlib.Path, required=True)
parser.add_argument("--godot", default="godot")
args = parser.parse_args()
project, output = args.project.resolve(), args.output.resolve()
if output == project or project in output.parents:
    parser.error("Output must be outside the project")
output.mkdir(parents=True, exist_ok=True)
env = dict(os.environ)
for key, folder in {"HOME": "home", "XDG_CONFIG_HOME": "config", "XDG_DATA_HOME": "data", "XDG_CACHE_HOME": "cache"}.items():
    path = output / folder
    path.mkdir(exist_ok=True)
    env[key] = str(path)

def input_hashes():
    paths = [project / name for name in ("project.godot", "export_presets.cfg", "art_source/alpha_bounds.json") if (project / name).is_file()]
    for folder in ("scripts", "data", "ui", "scenes", "assets", "tests", "tools"):
        paths.extend(p for p in (project / folder).rglob("*") if p.is_file() and p.suffix not in (".uid", ".pyc") and "__pycache__" not in p.parts)
    return {str(p.relative_to(project)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}

def success_marker(log):
    return bool(re.search(r'"failures"\s*:\s*\[\s*\]|failures=\[\]|\b0 failed\b|\b0 failures\b|^PASS:|UI_STRUCTURE_AND_INTENTS_PASS', log, re.M))

before = input_hashes()
records = []
def run(label, switches, marker=True):
    start = time.monotonic()
    try:
        result = subprocess.run([args.godot, "--headless", "--path", str(project), *switches], env=env, capture_output=True, text=True, timeout=180)
        log, code = result.stdout + result.stderr, result.returncode
    except subprocess.TimeoutExpired as error:
        # Preserve partial timeout streams; timeout remains native124 and rejected.
        partial_stdout = error.stdout or b""
        partial_stderr = error.stderr or b""
        stdout_bytes = partial_stdout.encode("utf-8") if isinstance(partial_stdout, str) else partial_stdout
        stderr_bytes = partial_stderr.encode("utf-8") if isinstance(partial_stderr, str) else partial_stderr
        (output / (label + ".timeout.stdout")).write_bytes(stdout_bytes)
        (output / (label + ".timeout.stderr")).write_bytes(stderr_bytes)
        log, code = stdout_bytes.decode("utf-8", errors="replace") + stderr_bytes.decode("utf-8", errors="replace") + "\n" + str(error), 124
    (output / (label + ".log")).write_text(log)
    record = {"test": label, "exit": code, "error": "ERROR:" in log, "success_marker": success_marker(log) if marker else None, "seconds": round(time.monotonic() - start, 3)}
    record["pass"] = code == 0 and not record["error"] and (not marker or record["success_marker"])
    records.append(record)
    (output / "summary.json").write_text(json.dumps(records, indent=2) + "\n")
    print(json.dumps(record), flush=True)

run("import", ["--editor", "--import", "--quit"], False)
tests = sorted((project / "tests").glob("*.gd")) + [project / "ui/test_ui.gd"] + sorted((project / "docs/art").glob("check*.gd"))
for test in tests:
    if not test.read_text().lstrip().startswith("extends SceneTree"):
        continue
    switches = ["--script", "res://" + str(test.relative_to(project))]
    promoted_feedback = {"independent_feedback_authority.gd", "independent_feedback_mixer.gd", "independent_feedback_views.gd", "independent_settlement_types.gd"}
    if test.name in promoted_feedback:
        switches += ["--", str(output / (test.stem + ".json"))]
        if test.name == "independent_feedback_mixer.gd":
            switches.append(str(output / "independent-mixer-raw"))
    run(test.name, switches)
after = input_hashes()
changed = sorted(key for key in before.keys() | after.keys() if before.get(key) != after.get(key))
(output / "input-hashes.json").write_text(json.dumps({"before": before, "after": after, "changed": changed}, indent=2) + "\n")
summary = {"entries": len(records) - 1, "passed": sum(record["pass"] for record in records), "import_included_in_passed": True, "input_changes": changed, "all_pass": all(record["pass"] for record in records) and not changed}
(output / "result.json").write_text(json.dumps(summary, indent=2) + "\n")
print(json.dumps(summary), flush=True)
raise SystemExit(0 if summary["all_pass"] else 1)
