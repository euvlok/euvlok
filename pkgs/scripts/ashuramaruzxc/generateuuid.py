#!/usr/bin/env python3

import argparse
import os
import re
import shutil
import uuid
from glob import glob


def main():
    # Argument parser setup
    parser = argparse.ArgumentParser(description="Rename files to UUIDs.")
    parser.add_argument("path", type=str)
    args = parser.parse_args()

    # Regular expression for UUID
    uuid4hex = re.compile(
        r"[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}"
    )

    # Regular expression for excluded formats
    excluded_formats = re.compile(
        r"\.(?:tar\.gz|tar\.bz2|tar\.xz|tar\.zst|tar\.lz4|tar\.lzma|tar\.lzo|tar\.Z|zip|7z|rar|bz2|xz|gz|zst|"
        r"tgz|tbz|tbz2|txz|tlz|tlzma|lzma|lz4|lzo|lzh|iso|cab|arj|cpio|rpm|deb|dmg|pkg|sit|hqx|bin|sea|ace|"
        r"z|Z|appimage|exe|msi|bat|com|dll|sys|bin|elf|dmg|dsk|run|sh|cmd|pdf|doc|docx|xls|xlsx|ppt|pptx|"
        r"odt|ods|odp|ott|ots|otp|tex|latex|md|markdown|rst|html|xml|json|yaml|yml|ini|csv|tsv|log|txt|m|"
        r"py|java|c|cpp|go|js|ts|rb|swift|php|pl|sh|bash|zsh|sql|r|dart|vb|vbs|lua|h|hpp|css|less|scss|aspx|jsp|"
        r"cbz|cbr|epub|mobi"
        r"asp|hbs|txt)$",
        re.IGNORECASE,
    )

    # Gather all files recursively
    all_files = glob(f"{args.path}/**/*", recursive=True)

    # Filter files to rename
    not_uuid = [
        fn
        for fn in all_files
        if (len(uuid4hex.findall(fn)) == 0)
        and (os.path.isfile(fn))
        and (not excluded_formats.search(fn))
    ]

    # Rename eligible files to UUID
    for fn in not_uuid:
        path, filename_ext = os.path.split(fn)
        ext = os.path.splitext(filename_ext)[1]

        new_uuid = uuid.uuid1()  # Generate a UUID1
        src = os.path.join(path, filename_ext)  # Source path
        dst = os.path.join(path, f"{new_uuid}{ext}")  # Destination path

        print(f"Renaming this file: {src} to {dst}")
        shutil.move(src=src, dst=dst)  # Rename file


if __name__ == "__main__":
    main()
