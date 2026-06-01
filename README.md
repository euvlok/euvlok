# EUVlok

<p>
  <a href="https://github.com/euvlok/euvlok/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/euvlok/euvlok/ci.yml?branch=master&style=for-the-badge&label=ci&colorA=303446&colorB=a6d189"></a>
  <a href="https://github.com/euvlok/euvlok/issues"><img alt="Open issues" src="https://img.shields.io/github/issues/euvlok/euvlok?style=for-the-badge&colorA=303446&colorB=ef9f76"></a>
  <a href="https://github.com/euvlok/euvlok"><img alt="License" src="https://img.shields.io/github/license/euvlok/euvlok?style=for-the-badge&colorA=303446&colorB=8caaee"></a>
</p>
EUVlok is a shared Nix flake for a few friends' machines. It contains NixOS,
nix-darwin, Home Manager, Chezmoi dotfiles, and small maintenance tools.

The point of keeping this together is practical: we can read each other's
configs, copy the parts that make sense, and move useful patterns into shared
modules instead of solving the same problems in separate repos.

This is not a starter template. It has real host configs, personal preferences,
encrypted secrets, and assumptions from the machines it serves. Copy pieces
carefully.

> [!IMPORTANT]
> Files under [`secrets/`](./secrets) are SOPS-encrypted and live next to the
> hosts that use them.

## Layout

| Path                                | What it is                                                       |
| ----------------------------------- | ---------------------------------------------------------------- |
| [`flake.nix`](./flake.nix)          | Top-level flake wiring and outputs.                              |
| [`flake-modules/`](./flake-modules) | Flake-parts modules for packages, checks, users, and dev shells. |
| [`hosts/`](./hosts)                 | NixOS, nix-darwin, and Home Manager entrypoints.                 |
| [`modules/`](./modules)             | Reusable Nix and Home Manager modules.                           |
| [`dotfiles/`](./dotfiles)           | Chezmoi dotfiles and templates.                                  |
| [`lib/`](./lib)                     | Shared Nix helpers.                                              |
| [`packages/`](./packages)           | Rust automation packages.                                        |
| [`secrets/`](./secrets)             | SOPS-encrypted host and user secrets.                            |

## Quick Start

```sh
nix develop
```

Run checks:

```sh
cargo check --workspace
cargo test --workspace
```

Format:

```sh
cargo fmt --all
nix fmt
```

Build a host:

```sh
nix build .#nixosConfigurations.nyx.config.system.build.toplevel
nix build .#darwinConfigurations.FlameFlags-Mac-mini.system
```

Run a local tool:

```sh
nix run .#auto-rebase
nix run .#browser-extension-update
nix run .#github-maintenance
nix run .#nvidia-prefetch
```

## Hosts

| Output                | Owner           | Platform   |
| --------------------- | --------------- | ---------- |
| `blind-faith`         | `lay-by`        | NixOS      |
| `nanachi`             | `bigshaq9999`   | NixOS      |
| `null`                | `sm-idk`        | NixOS      |
| `nyx`                 | `flameflag`     | NixOS      |
| `unsigned-int16`      | `ashuramaruzxc` | NixOS      |
| `unsigned-int32`      | `ashuramaruzxc` | NixOS      |
| `unsigned-int64`      | `ashuramaruzxc` | NixOS      |
| `FlameFlags-Mac-mini` | `flameflag`     | nix-darwin |
| `faputa`              | `bigshaq9999`   | nix-darwin |
| `unsigned-int8`       | `ashuramaruzxc` | nix-darwin |

Standalone Home Manager outputs are exposed for `ashuramaruzxc`, `bigshaq9999`,
`lay-by`, and `sm-idk`.

## Flake Outputs

Modules:

```nix
inputs.euvlok.nixosModules.default
inputs.euvlok.darwinModules.default
inputs.euvlok.homeModules.default
inputs.euvlok.homeModules.os
```

Apps and packages:

```text
auto-rebase
bootstrap
browser-extension-update
catppuccin-userstyles
chezmoi-support
github-maintenance
nvidia-prefetch
zellij-theme-tools
```

## Working Here

- Keep host-specific choices close to the host or user that needs them.
- Move repeated behavior into `modules/` or `lib/` once more than one setup uses
  it.
- Leave enough context that someone else in the repo can understand why a
  setting exists.
- Treat automation as source code and test behavior that can drift.
- Prefer explicit flake outputs over local conventions.
- Read the host that consumes a module before copying it somewhere else.

## Resources

- [nix.dev](https://nix.dev/)
- [NixOS Wiki](https://wiki.nixos.org/wiki/NixOS_Wiki)
- [Nixpkgs manual](https://nixos.org/manual/nixpkgs/stable/)
- [Home Manager options](https://home-manager-options.extranix.com/)
- [Noogle](https://noogle.dev/)
