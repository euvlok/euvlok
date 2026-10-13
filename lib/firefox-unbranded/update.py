#!/usr/bin/env python3
"""Pin Mozilla's prebuilt unbranded release artifacts and verify their checksums"""

import hashlib
import json
import os
import subprocess
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


def main():
    platforms = {}
    versions = set()
    for system, (job, archive) in PLATFORMS.items():
        namespace = f"gecko.v2.mozilla-release.latest.firefox.{job}"
        task = read_json(f"{ROOT}/index/v1/task/{namespace}")["taskId"]
        artifacts = f"{ROOT}/queue/v1/task/{task}/artifacts/public/build"
        metadata = read_json(f"{artifacts}/target.json")
        versions.add(metadata["moz_app_version"])
        with urllib.request.urlopen(
            f"{artifacts}/target.checksums"
        ) as response:
            checksums = response.read().decode().splitlines()
        expected = next(
            line.split()[0]
            for line in checksums
            if line.split()[1] == "sha512" and line.split()[3] == archive
        )
        url = f"{artifacts}/{archive}"
        print(f"Prefetching {system} Firefox {metadata['moz_app_version']}")
        fetched = json.loads(
            subprocess.run(
                ["nix", "store", "prefetch-file", "--json", url],
                check=True,
                capture_output=True,
                text=True,
            ).stdout
        )
        with open(fetched["storePath"], "rb") as source:
            actual = hashlib.file_digest(source, "sha512").hexdigest()
        if actual != expected:
            raise ValueError(f"Mozilla's SHA-512 checksum differs for {system}")
        platforms[system] = {
            "taskId": task,
            "buildId": metadata["buildid"],
            "url": url,
            "sha256": fetched["hash"],
        }
    if len(versions) != 1:
        raise ValueError(f"Platform builds have different versions: {versions}")
    destination = Path(__file__).with_name("source.json")
    temporary = destination.with_suffix(".json.tmp")
    temporary.write_text(
        json.dumps(
            {
                "version": versions.pop(),
                "platforms": platforms,
            },
            indent=2,
        )
        + "\n"
    )
    os.replace(temporary, destination)


if __name__ == "__main__":
    main()
