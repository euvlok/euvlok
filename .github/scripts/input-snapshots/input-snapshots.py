#!/usr/bin/env python3
"""Build and verify input snapshots for the current native configurations

The release's input-locks.tar.zst contains both consumer locks and manifest.json
Use restore --manifest manifest.json before adding modules or updating inputs
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import resource
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
import time
from pathlib import Path


def run(*args: str, **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(args, check=True, text=True, **kwargs)


def nix_json(*args: str) -> dict:
    return json.loads(run("nix", "--no-lazy-trees", *args, capture_output=True).stdout)


def write_json(path: Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")


def source_id(locked: dict) -> str:
    # Equal source trees share one asset even when several locks name them
    return hashlib.sha256(locked["narHash"].encode()).hexdigest()[:24]


def main_nixpkgs_source(locks: dict) -> str:
    lock = locks["flake.lock"]

    def resolve(path: tuple[str, ...], active: frozenset = frozenset()) -> str:
        if path in active:
            raise ValueError("Cyclic follows reference for the main Nixpkgs input")
        node = lock["root"]
        for name in path:
            target = lock["nodes"][node]["inputs"][name]
            node = (
                resolve(tuple(target), active | {path})
                if isinstance(target, list)
                else target
            )
        return node

    node = resolve(("nixpkgs",))
    return source_id(lock["nodes"][node]["locked"])


def archive_sources(lock: dict, archive: dict, relative: str, sources: dict) -> None:
    visited = set()

    def visit(node_name: str, tree: dict) -> None:
        if node_name in visited:
            return
        visited.add(node_name)
        node = lock["nodes"][node_name]
        if "locked" in node:
            locked = node["locked"]
            key = source_id(locked)
            entry = sources.setdefault(
                key, {"id": key, "source": tree["path"], "aliases": []}
            )
            entry["aliases"].append(
                {"lock": relative, "node": node_name, "locked": locked}
            )
        for name, target in node.get("inputs", {}).items():
            # Follows references reuse an already reachable lock node
            if isinstance(target, list):
                continue
            if name not in tree.get("inputs", {}):
                raise ValueError(f"Archive omitted {relative}:{node_name}/{name}")
            visit(target, tree["inputs"][name])

    visit(lock["root"], archive)
    missing = set(lock["nodes"]) - visited
    if missing:
        raise ValueError(f"Unarchived lock nodes in {relative}: {sorted(missing)}")


def inventory(project: Path, output: Path) -> None:
    sources = {}
    locks = {}
    root_hash = None
    for relative in ("flake.lock", "flake-modules/users/flake.lock"):
        directory = project / Path(relative).parent
        lock = json.loads((project / relative).read_text())
        archive = nix_json(
            "flake", "archive", "--json", "--no-write-lock-file", f"path:{directory}"
        )
        if root_hash is None:
            root_hash = run(
                "nix", "hash", "path", archive["path"], capture_output=True
            ).stdout.strip()
        locks[relative] = lock
        archive_sources(lock, archive, relative, sources)

    protected = main_nixpkgs_source(locks)
    for key, entry in sources.items():
        # Protect every alias of the main input, including the users partition
        entry["protected"] = key == protected

    identity = hashlib.sha256(
        json.dumps(
            {"locks": locks, "projectHash": root_hash},
            sort_keys=True,
            separators=(",", ":"),
        ).encode()
    ).hexdigest()
    write_json(
        output,
        {"version": 1, "lockDigest": identity, "locks": locks, "sources": sources},
    )
    print(f"Inventoried {len(sources)} distinct sources; main Nixpkgs stays upstream")


def evaluate(project: Path, system: str, nix: str = "nix", **kwargs) -> dict:
    def apply(attribute: str, expression: str | None = None, directory: Path = project):
        projection = ["--apply", expression] if expression else []
        result = run(
            nix,
            "--no-lazy-trees",
            "--no-eval-cache",
            "--eval-cores",
            "2",
            "--cores",
            "2",
            "--max-jobs",
            "2",
            "eval",
            "--json",
            "--no-write-lock-file",
            f"path:{directory}#{attribute}",
            *projection,
            capture_output=True,
            **kwargs,
        )
        return json.loads(result.stdout)

    # Release each host's evaluator heap before starting the next one
    names = apply(f"hostChecksBySystem.{system}", "builtins.attrNames")
    output = {"hosts": {}}
    for name in names:
        quoted = json.dumps(name).replace("${", r"\${")
        output["hosts"][name] = apply(f"hostChecksBySystem.{system}.{quoted}")
    for group in ("packages", "checks", "devShells"):
        output[group] = apply(
            f"{group}.{system}", "builtins.mapAttrs (_: value: value.drvPath)"
        )
    output["userChecks"] = apply(
        f"checks.{system}",
        "builtins.mapAttrs (_: value: value.drvPath)",
        project / "flake-modules/users",
    )
    return output


def trace(project: Path, inventory_path: Path, system: str, nix: str, output: Path):
    data = json.loads(inventory_path.read_text())
    output.mkdir(parents=True, exist_ok=True)
    log = output / "accesses.jsonl"
    if log.exists():
        raise ValueError(f"Refusing to reuse an existing trace: {log}")
    baseline = evaluate(
        project, system, nix, env=os.environ | {"EUVLOK_SOURCE_TRACE": str(log)}
    )
    if not log.exists() or not log.stat().st_size:
        raise ValueError("Evaluator produced no source trace; use input-trace-nix")
    write_json(output / "baseline.json", baseline)
    roots = {entry["source"]: key for key, entry in data["sources"].items()}
    usage = {
        key: {
            "read": set(),
            "stat": set(),
            "list": set(),
            "link": set(),
            "whole": False,
        }
        for key in data["sources"]
    }
    with log.open() as records:
        for line in records:
            record = json.loads(line)
            path = Path(record["path"])
            for parent in (path, *path.parents):
                if str(parent) in roots:
                    if record.get("virtual"):
                        raise ValueError(
                            f"Input access has no physical path: {path}; disable lazy trees"
                        )
                    key = roots[str(parent)]
                    usage[key][record["op"]].add(path.relative_to(parent).as_posix())
                    break
    derivations = sorted({drv for group in baseline.values() for drv in group.values()})
    # Already-present store paths can become build inputs without evaluator
    # reads, so include the recursive derivation closure as well
    references = run(
        "nix-store", "--query", "--requisites", *derivations, capture_output=True
    )
    for reference in references.stdout.splitlines():
        if reference in roots:
            usage[roots[reference]]["whole"] = True
    serialized = {
        key: {
            op: sorted(paths) if isinstance(paths, set) else paths
            for op, paths in value.items()
        }
        for key, value in usage.items()
    }
    write_json(output / "usage.json", {"system": system, "sources": serialized})
    print(f"Traced {len(derivations)} derivations on {system}")


def prune_source(
    source: Path, destination: Path, usage: dict, flake_dirs: set[str]
) -> dict:
    if usage["whole"] or not any(usage[op] for op in ("read", "stat", "list", "link")):
        return {
            "pruned": False,
            "reason": "whole-tree dependency or no observed accesses",
        }
    content = set(usage["read"]) | set(usage["link"])
    metadata = set(usage["stat"]) | content | set(usage["list"]) | {"."}
    # Preserve directory entry names/types even if their contents were unused
    for relative in usage["list"]:
        metadata.update(
            (Path(relative) / child.name).as_posix()
            for child in (source / relative).iterdir()
        )
    for directory in flake_dirs:
        for name in ("flake.nix", "flake.lock"):
            relative = (Path(directory) / name).as_posix()
            if (source / relative).exists():
                content.add(relative)
                metadata.add(relative)
    for relative in list(metadata):
        metadata.update(parent.as_posix() for parent in Path(relative).parents)
    destination.mkdir()
    before = after = kept = placeholders = 0
    for path in source.rglob("*"):
        if path.is_file() and not path.is_symlink():
            before += path.stat().st_size
    for relative in sorted(metadata, key=lambda item: (len(Path(item).parts), item)):
        path = source / relative
        target = destination / relative
        if path.is_symlink():
            target.symlink_to(os.readlink(path))
        elif path.is_dir():
            target.mkdir(exist_ok=True)
        elif relative in content:
            shutil.copy2(path, target)
            after += path.stat().st_size
            kept += 1
        else:
            target.touch()
            target.chmod(0o755 if path.stat().st_mode & stat.S_IXUSR else 0o644)
            placeholders += 1
    return {
        "pruned": True,
        "beforeBytes": before,
        "afterBytes": after,
        "keptFiles": kept,
        "placeholders": placeholders,
    }


def merge_usage(directory: Path, key: str) -> dict:
    merged = {
        "read": set(),
        "stat": set(),
        "list": set(),
        "link": set(),
        "whole": False,
    }
    systems = set()
    for path in directory.glob("*/usage.json"):
        value = json.loads(path.read_text())
        systems.add(value["system"])
        usage = value["sources"][key]
        merged["whole"] |= usage["whole"]
        for op in ("read", "stat", "list", "link"):
            merged[op].update(usage[op])
    expected = {"aarch64-darwin", "aarch64-linux", "x86_64-linux"}
    if systems != expected:
        raise ValueError(
            f"Incomplete native traces: expected {expected}, got {systems}"
        )
    return merged


def fetch_source(entry: dict) -> Path:
    # Each compression job can fetch its source on a different runner
    locked = dict(entry["aliases"][0]["locked"])
    locked.pop("dir", None)
    encoded = json.dumps(json.dumps(locked)).replace("${", r"\${")
    result = nix_json(
        "eval",
        "--impure",
        "--json",
        "--expr",
        f"let tree = builtins.fetchTree (builtins.fromJSON {encoded}); "
        "in { inherit (tree) narHash; sourcePath = tree.outPath; }",
    )
    if result["narHash"] != locked["narHash"]:
        raise ValueError("Fetched source differs from its upstream lock")
    return Path(result["sourcePath"])


def deterministic_tar(source: Path, destination: Path) -> None:
    with tarfile.open(destination, "w", format=tarfile.PAX_FORMAT) as archive:

        def add(path: Path, name: str) -> None:
            info = archive.gettarinfo(str(path), arcname=name)
            info.uid = info.gid = info.mtime = 0
            info.uname = info.gname = ""
            info.pax_headers = {}
            if info.isdir():
                info.mode = 0o755
            elif info.isfile():
                info.mode = 0o755 if info.mode & stat.S_IXUSR else 0o644
            if info.isfile():
                with path.open("rb") as body:
                    archive.addfile(info, body)
            else:
                archive.addfile(info)
            if info.isdir():
                for child in sorted(path.iterdir(), key=lambda item: item.name):
                    add(child, f"{name}/{child.name}")

        add(source, "source")


def pack(
    inventory_path: Path,
    key: str,
    output: Path,
    timeout: int,
    traces: Path | None = None,
) -> None:
    data = json.loads(inventory_path.read_text())
    if key == main_nixpkgs_source(data["locks"]):
        raise ValueError("The main Nixpkgs input must not be pruned or repacked")
    entry = data["sources"][key]
    source = fetch_source(entry)
    output.mkdir(parents=True, exist_ok=True)
    expected_hash = entry["aliases"][0]["locked"]["narHash"]
    result = {
        "id": key,
        "upstreamHash": expected_hash,
        "sourceHash": expected_hash,
        "candidates": [],
    }
    # Bound the compressor before it can trigger the runner's OOM killer
    memory_limit = 4 * 1024**3
    if Path("/proc/meminfo").exists():
        available = next(
            line
            for line in Path("/proc/meminfo").read_text().splitlines()
            if line.startswith("MemAvailable:")
        )
        memory_limit = max(
            512 * 1024**2, int(available.split()[1]) * 1024 - 2 * 1024**3
        )

    def limit_memory():
        resource.setrlimit(resource.RLIMIT_AS, (memory_limit, memory_limit))

    if source.is_file():
        # A file input is not automatically unpacked by Nix's file fetcher
        asset = output / f"{key}.file"
        shutil.copy2(source, asset)
        fetched = nix_json("flake", "prefetch", "--json", f"file+{asset.as_uri()}")
        if fetched["hash"] != expected_hash:
            raise ValueError("Mirrored file failed Nix source-hash verification")
        result.update(asset=asset.name, type="file", bytes=asset.stat().st_size)
    else:
        with tempfile.TemporaryDirectory(prefix="input-snapshot-", dir=output) as temp:
            work = Path(temp)
            if traces:
                pruned = work / "pruned"
                result["pruning"] = prune_source(
                    source,
                    pruned,
                    merge_usage(traces, key),
                    {alias["locked"].get("dir", ".") for alias in entry["aliases"]},
                )
                if result["pruning"]["pruned"]:
                    source = pruned
                    expected_hash = run(
                        "nix", "hash", "path", str(source), capture_output=True
                    ).stdout.strip()
                    result["sourceHash"] = expected_hash
            tar = work / "source.tar"
            deterministic_tar(source, tar)
            result["tarBytes"] = tar.stat().st_size
            candidates = (
                ("19", ["-19"]),
                ("22", ["--ultra", "-22"]),
                ("max", ["--max"]),
            )
            best = None
            for name, flags in candidates:
                candidate = work / f"source-{name}.tar.zst"
                started = time.monotonic()
                # Nix's archive decoder rejects frames needing more than
                # 128 MiB of window memory, including otherwise valid zstd
                try:
                    run(
                        "zstd",
                        *flags,
                        "--long=27",
                        "-T1",
                        "-q",
                        str(tar),
                        "-o",
                        str(candidate),
                        timeout=timeout,
                        capture_output=True,
                        preexec_fn=limit_memory,
                    )
                except subprocess.TimeoutExpired:
                    result["candidates"].append({"setting": name, "timedOut": True})
                    continue
                except subprocess.CalledProcessError as error:
                    result["candidates"].append(
                        {
                            "setting": name,
                            "failed": error.returncode,
                            "reason": error.stderr.strip()[:512],
                        }
                    )
                    continue
                fetched = nix_json(
                    "flake", "prefetch", "--json", f"tarball+{candidate.as_uri()}"
                )
                if fetched["hash"] != expected_hash:
                    raise ValueError(f"{key}/{name} changed the unpacked source tree")
                size = candidate.stat().st_size
                result["candidates"].append(
                    {
                        "setting": name,
                        "bytes": size,
                        "seconds": round(time.monotonic() - started, 3),
                    }
                )
                if best is None or size < best[0]:
                    best = (size, name)
            if best is None:
                raise ValueError(f"No compression candidate completed for {key}")
            asset = output / f"{key}.tar.zst"
            shutil.copyfile(work / f"source-{best[1]}.tar.zst", asset)
            result.update(
                asset=asset.name, type="tarball", bytes=best[0], setting=best[1]
            )

    result["sha256"] = hashlib.sha256(asset.read_bytes()).hexdigest()
    write_json(output / f"{key}.json", result)
    print(f"Verified {asset.name}: {result['bytes']} bytes")


def snapshot_locked(original: dict, result: dict, url: str) -> dict:
    locked = {"type": result["type"], "url": url, "narHash": result["sourceHash"]}
    for attribute in ("lastModified", "rev", "revCount", "dir", "name"):
        if attribute in original:
            locked[attribute] = original[attribute]
    return locked


def snapshot_locks(
    inventory_path: Path, assets: Path, base_url: str, output: Path
) -> None:
    data = json.loads(inventory_path.read_text())
    manifest = {"version": 1, "lockDigest": data["lockDigest"], "sources": {}}
    protected = main_nixpkgs_source(data["locks"])
    for key, entry in data["sources"].items():
        if key == protected:
            manifest["sources"][key] = {
                "protected": True,
                "reason": "Main Nixpkgs remains pinned to its upstream source",
                "aliases": entry["aliases"],
            }
            continue
        result = json.loads((assets / f"{key}.json").read_text())
        asset = assets / result["asset"]
        if hashlib.sha256(asset.read_bytes()).hexdigest() != result["sha256"]:
            raise ValueError(f"Asset checksum mismatch: {asset.name}")
        url = f"{base_url.rstrip('/')}/{asset.name}"
        manifest["sources"][key] = result | {"url": url, "aliases": entry["aliases"]}
        for alias in entry["aliases"]:
            original = alias["locked"]
            locked = snapshot_locked(original, result, url)
            # Keep original references so normal updates still consult upstream
            data["locks"][alias["lock"]]["nodes"][alias["node"]]["locked"] = locked
    for relative, lock in data["locks"].items():
        write_json(output / relative, lock)
    write_json(output / "manifest.json", manifest)


def restore(project: Path, manifest_path: Path) -> None:
    manifest = json.loads(manifest_path.read_text())
    locks = {
        relative: json.loads((project / relative).read_text())
        for relative in ("flake.lock", "flake-modules/users/flake.lock")
    }
    restored = 0
    for source in manifest["sources"].values():
        if source.get("protected"):
            continue
        for alias in source["aliases"]:
            node = locks[alias["lock"]]["nodes"].get(alias["node"], {})
            # Leave any input already updated independently untouched
            if node.get("locked") == snapshot_locked(
                alias["locked"], source, source["url"]
            ):
                node["locked"] = alias["locked"]
                restored += 1
    for relative, lock in locks.items():
        write_json(project / relative, lock)
    print(f"Restored {restored} upstream lock entries")


def verify(
    project: Path,
    inventory_path: Path,
    assets: Path,
    baseline: Path,
    system: str,
    output: Path,
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="input-consumer-", dir=output) as temp:
        consumer = Path(temp) / "project"
        shutil.copytree(
            project,
            consumer,
            symlinks=True,
            ignore=shutil.ignore_patterns(".git", ".jj", "node_modules", "result"),
        )
        snapshot_locks(inventory_path, assets, assets.as_uri(), consumer)
        original = evaluate(consumer, system)
        expected = json.loads(baseline.read_text())
        write_json(output / "actual.json", original)
        differences = {
            group: [
                name
                for name in set(expected[group]) | set(actual)
                if expected[group].get(name) != actual.get(name)
            ]
            for group, actual in original.items()
        }
        # The manifest check embeds the repository, including changed locks
        # Require it to pass instead of retaining its old source path
        built_checks = []
        for group, directory in (
            ("checks", consumer),
            ("userChecks", consumer / "flake-modules/users"),
        ):
            if (
                "check-flake-file" in expected[group]
                and "check-flake-file" in original[group]
            ):
                differences[group] = [
                    name for name in differences[group] if name != "check-flake-file"
                ]
                built_checks.append((group, directory))
        differences = {group: names for group, names in differences.items() if names}
        write_json(
            output / "verification.json", {"system": system, "differences": differences}
        )
        if differences:
            raise ValueError(f"Snapshot changed derivations on {system}: {differences}")
        for _, directory in built_checks:
            run(
                "nix",
                "--eval-cores",
                "2",
                "--cores",
                "2",
                "--max-jobs",
                "2",
                "build",
                "--no-link",
                "--no-write-lock-file",
                f"path:{directory}#checks.{system}.check-flake-file",
            )
        write_json(
            output / "verification.json",
            {
                "system": system,
                "differences": differences,
                "builtChecks": [
                    f"{group}.check-flake-file" for group, _ in built_checks
                ],
            },
        )
        print(
            f"Snapshot preserves native derivations and passes manifest checks on {system}"
        )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    collect = commands.add_parser("inventory")
    collect.add_argument("--project", type=Path, default=Path.cwd())
    collect.add_argument("--output", type=Path, required=True)
    compress = commands.add_parser("pack")
    compress.add_argument("--inventory", type=Path, required=True)
    compress.add_argument("--id", required=True)
    compress.add_argument("--output", type=Path, required=True)
    compress.add_argument("--timeout", type=int, default=900)
    compress.add_argument("--traces", type=Path)
    locks = commands.add_parser("locks")
    locks.add_argument("--inventory", type=Path, required=True)
    locks.add_argument("--assets", type=Path, required=True)
    locks.add_argument("--base-url", required=True)
    locks.add_argument("--output", type=Path, required=True)
    collect_trace = commands.add_parser("trace")
    collect_trace.add_argument("--project", type=Path, default=Path.cwd())
    collect_trace.add_argument("--inventory", type=Path, required=True)
    collect_trace.add_argument("--system", required=True)
    collect_trace.add_argument("--nix", required=True)
    collect_trace.add_argument("--output", type=Path, required=True)
    validate = commands.add_parser("verify")
    validate.add_argument("--project", type=Path, default=Path.cwd())
    validate.add_argument("--inventory", type=Path, required=True)
    validate.add_argument("--assets", type=Path, required=True)
    validate.add_argument("--baseline", type=Path, required=True)
    validate.add_argument("--system", required=True)
    validate.add_argument("--output", type=Path, required=True)
    reset = commands.add_parser(
        "restore",
        help="Restore upstream locks before changing the configuration or updating inputs",
    )
    reset.add_argument("--project", type=Path, default=Path.cwd())
    reset.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()
    if args.command == "inventory":
        inventory(args.project.resolve(), args.output.resolve())
    elif args.command == "pack":
        pack(
            args.inventory.resolve(),
            args.id,
            args.output.resolve(),
            args.timeout,
            args.traces,
        )
    elif args.command == "locks":
        snapshot_locks(args.inventory, args.assets, args.base_url, args.output)
    elif args.command == "trace":
        trace(
            args.project.resolve(),
            args.inventory,
            args.system,
            args.nix,
            args.output.resolve(),
        )
    elif args.command == "verify":
        verify(
            args.project.resolve(),
            args.inventory,
            args.assets.resolve(),
            args.baseline,
            args.system,
            args.output.resolve(),
        )
    else:
        restore(args.project.resolve(), args.manifest.resolve())


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        if error.stderr:
            print(error.stderr, file=sys.stderr)
        sys.exit(error.returncode)
