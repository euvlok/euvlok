import argparse
import json
import subprocess
from pathlib import Path


def discover_skill_directories(roots: list[Path]) -> list[str]:
    directories: set[str] = set()
    for root in roots:
        if not root.exists():
            continue
        for skill_file in root.rglob("SKILL.md"):
            if skill_file.is_file():
                directories.add(str(skill_file.parent.parent.resolve()))
    return sorted(directories)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--omp", required=True)
    parser.add_argument("--settings", type=Path, required=True)
    parser.add_argument("--skill-root", type=Path, action="append", default=[])
    args = parser.parse_args()

    settings = json.loads(args.settings.read_text())
    directories = settings.get("skills.customDirectories", [])
    settings["skills.customDirectories"] = sorted(
        set(directories) | set(discover_skill_directories(args.skill_root))
    )
    for key, value in settings.items():
        command_value = value if isinstance(value, str) else json.dumps(value)
        subprocess.run(
            [args.omp, "config", "set", key, command_value],
            check=True,
            timeout=30,
        )


if __name__ == "__main__":
    main()
