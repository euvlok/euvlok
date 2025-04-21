import argparse
import hashlib
import os
import re
import shutil
from glob import glob


def main():
    # Create an argument parser for input path
    parser = argparse.ArgumentParser(
        description="Script that renames files to MD5 hashes."
    )
    parser.add_argument("path", type=str)
    args = parser.parse_args()

    # Gather all files recursively from the input path
    all_files = glob(f"{args.path}/**/*", recursive=True)

    # Regular expression to match MD5 hash pattern
    md5hex = re.compile(r"[0-9a-f]{32}")

    # Regular expression for archive and binary formats (to exclude from renaming)
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

    # Filter out files that are already MD5 hashed or match the archive/binary extensions
    not_hashed = [
        fn
        for fn in all_files
        if (
            len(md5hex.findall(fn)) == 0
            and os.path.isfile(fn)
            and not excluded_formats.search(fn)
        )
    ]

    # Rename files that are not hashed and don't match the exclusion patterns
    for fn in not_hashed:
        path, filename_ext = os.path.split(fn)
        only_filename, ext = os.path.splitext(filename_ext)

        # Compute MD5 hash of the filename
        md5_hash = hashlib.md5(only_filename.encode()).hexdigest()

        # Source and destination paths
        src = f"{path}/{only_filename}{ext}"
        dst = f"{path}/{md5_hash}{ext}"

        print("Renaming this file:", src, "to", dst)
        shutil.move(src=src, dst=dst)


if __name__ == "__main__":
    main()
