#!/usr/bin/env python3
"""Discover unbranded Taskcluster artifacts, then delegate updates to nix-update"""

import json
import os
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = "https://firefox-ci-tc.services.mozilla.com/api"
PLATFORMS = {
    "x86_64-linux": ("linux64-add-on-devel", "target.tar.xz"),
    "aarch64-darwin": ("macosx64-aarch64-add-on-devel", "target.dmg"),
}


def read_json(url):
    with urllib.request.urlopen(url) as response:
        return json.load(response)


def write_pins(destination, contents):
    temporary = destination.with_suffix(".json.tmp")
    temporary.write_text(contents)
    os.replace(temporary, destination)


def main():
    destination = Path("lib/firefox-unbranded/source.json")
    original = destination.read_text()
    sources = json.loads(original)
    platforms = {}
    versions = set()
    for system, (job, archive) in PLATFORMS.items():
        namespace = f"gecko.v2.mozilla-release.latest.firefox.{job}"
        task = read_json(f"{ROOT}/index/v1/task/{namespace}")["taskId"]
        artifacts = f"{ROOT}/queue/v1/task/{task}/artifacts/public/build"
        metadata = read_json(f"{artifacts}/target.json")
        versions.add(metadata["moz_app_version"])
        platforms[system] = {
            "taskId": task,
            "buildId": metadata["buildid"],
            "url": f"{artifacts}/{archive}",
            "sha256": sources["platforms"][system]["sha256"],
        }
    if len(versions) != 1:
        raise ValueError(f"Platform builds have different versions: {versions}")

    # Preserve the old version and hashes for nix-update to replace
    sources["platforms"] = platforms
    write_pins(destination, json.dumps(sources, indent=2) + "\n")
    try:
        subprocess.run(
            [*sys.argv[1:], f"--version={versions.pop()}"],
            check=True,
        )
    except (subprocess.CalledProcessError, KeyboardInterrupt):
        write_pins(destination, original)
        raise


if __name__ == "__main__":
    main()
