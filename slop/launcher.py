import argparse
import asyncio
import json
import os
import sys
from collections.abc import AsyncIterator, Iterator, Mapping, Sequence
from contextlib import asynccontextmanager, suppress
from dataclasses import dataclass, field
from itertools import count
from pathlib import Path
from typing import cast


@dataclass
class AppServer:
    process: asyncio.subprocess.Process
    identifiers: Iterator[int] = field(default_factory=lambda: count(1))

    async def send(self, payload: Mapping[str, object]) -> None:
        if self.process.stdin is None:
            raise RuntimeError("Codex app server has no input stream")
        self.process.stdin.write(json.dumps(payload).encode() + b"\n")
        await self.process.stdin.drain()

    async def request(self, method: str, params: Mapping[str, object]) -> object:
        identifier = next(self.identifiers)
        try:
            async with asyncio.timeout(5):
                await self.send(
                    {
                        "jsonrpc": "2.0",
                        "id": identifier,
                        "method": method,
                        "params": params,
                    }
                )
                return await self.receive(identifier)
        except TimeoutError as exc:
            raise TimeoutError(f"Codex {method} response timed out") from exc

    async def receive(self, identifier: int) -> object:
        if self.process.stdout is None:
            raise RuntimeError("Codex app server has no output stream")
        async for line in self.process.stdout:
            payload: object = json.loads(line)
            response = (
                cast("dict[str, object]", payload) if isinstance(payload, dict) else {}
            )
            if "method" in response or response.get("id") != identifier:
                continue
            if "error" in response:
                raise RuntimeError(response["error"])
            return response.get("result")
        raise RuntimeError("Codex app server exited")


@asynccontextmanager
async def app_server(real: Path) -> AsyncIterator[AppServer]:
    process = await asyncio.create_subprocess_exec(
        real,
        "app-server",
        "--stdio",
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.DEVNULL,
        limit=16 * 1024 * 1024,
    )
    try:
        server = AppServer(process)
        await server.request(
            "initialize",
            {"clientInfo": {"name": "codex-launcher", "version": "1"}},
        )
        async with asyncio.timeout(5):
            await server.send({"jsonrpc": "2.0", "method": "initialized"})
        yield server
    finally:
        with suppress(ProcessLookupError):
            process.terminate()
        try:
            async with asyncio.timeout(3):
                await process.communicate()
        except TimeoutError:
            with suppress(ProcessLookupError):
                process.kill()
            await process.communicate()


async def trust_launch_hooks(real: Path, cwd: Path) -> None:
    async with app_server(real) as server:
        await trust_hooks(server, cwd)


async def trust_hooks(server: AppServer, cwd: Path) -> None:
    result = await server.request("hooks/list", {"cwds": [os.fspath(cwd)]})
    data = result.get("data") if isinstance(result, dict) else None
    if not isinstance(data, list):
        raise TypeError("Codex hooks/list returned an invalid response")
    for entry in data:
        if not isinstance(entry, dict) or entry.get("cwd") != os.fspath(cwd):
            continue
        if entry.get("errors"):
            raise RuntimeError("Codex hooks/list could not load launch hooks")
        hooks = entry.get("hooks")
        if not isinstance(hooks, list):
            raise TypeError("Codex hooks/list returned invalid hooks")
        trust = hook_trust_state(hooks)
        if trust:
            await write_hook_trust(server, trust)
        return
    raise RuntimeError("Codex hooks/list did not include the launch directory")


def hook_trust_state(hooks: Sequence[object]) -> dict[object, dict[str, object]]:
    return {
        cast("dict[str, object]", hook)["key"]: {
            "trusted_hash": cast("dict[str, object]", hook)["currentHash"]
        }
        for hook in hooks
        if isinstance(hook, dict)
        and hook.get("trustStatus") in {"untrusted", "modified"}
    }


async def write_hook_trust(
    server: AppServer, trust: dict[object, dict[str, object]]
) -> None:
    await server.request(
        "config/batchWrite",
        {
            "edits": [
                {
                    "keyPath": "hooks.state",
                    "mergeStrategy": "upsert",
                    "value": trust,
                }
            ],
            "reloadUserConfig": True,
        },
    )


def main() -> None:
    real = Path(os.environ["CODEX_REAL_BIN"])
    interactive = sys.stdin.isatty() and sys.stdout.isatty()
    if interactive:
        parser = argparse.ArgumentParser(
            prog="codex", add_help=False, allow_abbrev=False
        )
        parser.add_argument("-C", "--cd", type=Path, default=Path.cwd())
        options, _ = parser.parse_known_args()
        cwd = options.cd.resolve()
        try:
            asyncio.run(trust_launch_hooks(real, cwd))
        except (
            OSError,
            RuntimeError,
            TimeoutError,
            TypeError,
            ValueError,
            KeyError,
        ) as exc:
            raise SystemExit(f"codex: could not trust launch hooks: {exc}") from exc

    # Hook trust bypass is for automation and forces interactive sessions into
    # embedded mode instead of the shared background server
    hook_trust_flag = [] if interactive else ["--dangerously-bypass-hook-trust"]
    os.execv(real, [os.fspath(real), *hook_trust_flag, *sys.argv[1:]])


if __name__ == "__main__":
    main()
