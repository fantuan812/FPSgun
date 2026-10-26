#!/usr/bin/env python3
"""Verify and restore exact delivered files from a local FPSgun checkout.

No network, archive extraction, installation, or program execution is performed.
Existing destination files are never overwritten. A verified temporary file is
published with an exclusive hard link (supported on Linux and Windows NTFS).
"""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import tempfile


def safe_relative(value):
    if not isinstance(value, str) or not value or "\\" in value or ":" in value:
        raise ValueError("Unsafe relative path")
    p = PurePosixPath(value)
    if p.is_absolute() or any(x in ("", ".", "..") for x in value.split("/")):
        raise ValueError("Unsafe relative path")
    return p


def source_path(root, value):
    rel = safe_relative(value)
    p = root
    for component in rel.parts:
        p = p / component
        if p.is_symlink():
            raise ValueError("Source symlinks are not accepted")
    if not p.is_file():
        raise ValueError("Missing source file: " + value)
    return p


def checked_parts(record):
    storage = record["storage"]
    if storage["kind"] in ("direct", "existing"):
        return [{"path": storage["path"], "size": record["size"],
                 "sha256": record["sha256"],
                 "git_blob_sha": record["original_git_blob_sha"]}]
    if storage["kind"] != "chunks" or not storage.get("chunks"):
        raise ValueError("Unknown or empty storage")
    if sum(x["size"] for x in storage["chunks"]) != record["size"]:
        raise ValueError("Chunk sizes do not cover original")
    if len({x["path"] for x in storage["chunks"]}) != len(storage["chunks"]):
        raise ValueError("Repeated chunk path")
    offset = 0
    for part in storage["chunks"]:
        if part.get("offset") != offset:
            raise ValueError("Non-contiguous or reordered chunks")
        offset += part["size"]
    return storage["chunks"]


def stream_verified(root, record, output=None):
    whole = hashlib.sha256()
    total = 0
    whole_git = hashlib.sha1(b"blob " + str(record["size"]).encode() + b"\0")
    for part in checked_parts(record):
        if not isinstance(part["size"], int) or part["size"] < 0:
            raise ValueError("Invalid chunk length")
        h = hashlib.sha256()
        g = hashlib.sha1(b"blob " + str(part["size"]).encode() + b"\0")
        count = 0
        with source_path(root, part["path"]).open("rb") as f:
            while data := f.read(1024 * 1024):
                count += len(data)
                if count > part["size"]:
                    raise ValueError("Oversized chunk")
                h.update(data); g.update(data); whole.update(data); whole_git.update(data)
                if output is not None:
                    output.write(data)
        if count != part["size"] or h.hexdigest() != part["sha256"] or g.hexdigest() != part["git_blob_sha"]:
            raise ValueError("Chunk identity mismatch: " + part["path"])
        total += count
    if total != record["size"] or whole.hexdigest() != record["sha256"] or whole_git.hexdigest() != record["original_git_blob_sha"]:
        raise ValueError("Original identity mismatch: " + record["name"])


def restore(root, record, destination):
    name = safe_relative(record["name"])
    if len(name.parts) != 1:
        raise ValueError("Original filename must be a basename")
    target = destination / record["name"]
    if target.exists() or target.is_symlink():
        raise FileExistsError("Refusing to overwrite " + str(target))
    temp = None
    try:
        with tempfile.NamedTemporaryFile(prefix=".moss-restore-", dir=destination, delete=False) as out:
            temp = Path(out.name)
            stream_verified(root, record, out)
            out.flush(); os.fsync(out.fileno())
        os.link(temp, target)  # Atomic no-clobber: fails if destination appeared.
    finally:
        if temp is not None:
            temp.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="For example v25")
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--catalog", type=Path, default=Path(__file__).with_name("CATALOG.json"))
    parser.add_argument("--output", type=Path, help="New or existing output directory; existing files are refused")
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    root = args.repo_root.resolve(strict=True)
    records = [r for r in json.loads(args.catalog.read_text(encoding="utf-8"))["files"] if r["version"] == args.version]
    if not records:
        parser.error("No delivered files for this version")
    if len({r["name"] for r in records}) != len(records):
        raise ValueError("Duplicate original filenames")
    if not args.verify_only:
        if args.output is None:
            parser.error("--output is required unless --verify-only")
        # Refuse symlinks in all existing output ancestors, not only the leaf.
        absolute = args.output.absolute()
        if any(p.is_symlink() for p in (absolute, *absolute.parents)):
            raise ValueError("Output symlinks are not accepted")
        args.output.mkdir(parents=True, exist_ok=True)
        for r in records:
            name = safe_relative(r["name"])
            if len(name.parts) != 1 or (args.output / r["name"]).exists() or (args.output / r["name"]).is_symlink():
                raise ValueError("Invalid or existing output file")
    for record in records:
        if args.verify_only:
            stream_verified(root, record)
        else:
            restore(root, record, args.output)
        print("Verified: " + record["name"])
    print("All selected originals match their recorded SHA-256 and Git blob IDs.")


if __name__ == "__main__":
    main()
