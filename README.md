<div align="center">
  <picture>
    <source
      media="(prefers-color-scheme: dark)"
      srcset="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png"
    />
    <img
      alt="Catppuccin palette strip"
      src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/latte.png"
      width="520"
    />
  </picture>

  <h1>EUVlok</h1>

  <p>
    <strong>A communal Nix flake for shared systems, homes, dotfiles, and the small tools that keep them moving.</strong>
  </p>

  <p>
    <a href="https://github.com/euvlok/euvlok/actions/workflows/ci.yml">
      <img alt="CI" src="https://img.shields.io/github/actions/workflow/status/euvlok/euvlok/ci.yml?branch=main&style=for-the-badge&label=ci&colorA=303446&colorB=a6d189">
    </a>
    <a href="https://github.com/euvlok/euvlok/stargazers">
      <img alt="GitHub stars" src="https://img.shields.io/github/stars/euvlok/euvlok?style=for-the-badge&colorA=303446&colorB=ca9ee6">
    </a>
    <a href="https://github.com/euvlok/euvlok/issues">
      <img alt="Open issues" src="https://img.shields.io/github/issues/euvlok/euvlok?style=for-the-badge&colorA=303446&colorB=ef9f76">
    </a>
    <a href="./LICENSE.txt">
      <img alt="License" src="https://img.shields.io/github/license/euvlok/euvlok?style=for-the-badge&colorA=303446&colorB=8caaee">
    </a>
  </p>
</div>

---

<table>
  <tr>
    <td><strong>Systems</strong></td>
    <td>NixOS, nix-darwin, and standalone Home Manager configurations.</td>
  </tr>
  <tr>
    <td><strong>Dotfiles</strong></td>
    <td>Chezmoi-managed user files, templates, scripts, and application config.</td>
  </tr>
  <tr>
    <td><strong>Modules</strong></td>
    <td>Reusable Nix modules for hosts, homes, terminals, shells, services, themes, and desktop environments.</td>
  </tr>
  <tr>
    <td><strong>Tooling</strong></td>
    <td>Bun/TypeScript utilities for repository automation, browser extension updates, userstyle builds, and NVIDIA prefetching.</td>
  </tr>
</table>

## Why This Exists

EUVlok is where a few friends keep their machines understandable together.

The name is half European Union, half Dutch: `EU` for the European Union and
`vlok` for "flake." The Dutch nod is intentional; Nix began in the Netherlands,
and this repo is very much in that lineage of declarative systems, careful
composition, and the occasional strongly held opinion about a shell prompt.

This repository is not a pristine starter template. It is a working garden of
real machines, real habits, and shared abstractions that have survived contact
with daily use. The goal is to make personal infrastructure easier to inspect,
borrow from, improve, and repair.

## What Is Inside

| Path                                | Purpose                                                                                            |
| ----------------------------------- | -------------------------------------------------------------------------------------------------- |
| [`flake.nix`](./flake.nix)          | Top-level flake inputs, partitions, systems, and shared output wiring.                             |
| [`flake-modules/`](./flake-modules) | Flake-parts modules for packages, exported modules, users, checks, and the development shell.      |
| [`hosts/`](./hosts)                 | NixOS, nix-darwin, and Home Manager host/user entrypoints.                                         |
| [`modules/`](./modules)             | Reusable modules for NixOS, nix-darwin, Home Manager, cross-platform defaults, and helper scripts. |
| [`dotfiles/`](./dotfiles)           | Chezmoi dotfiles and templates for user-space configuration.                                       |
| [`lib/`](./lib)                     | Shared Nix helpers for Catppuccin, Ghostty, Kanata, Yazi, Zellij, and general module ergonomics.   |
| [`packages/`](./packages)           | Bun-powered automation packages and shared TypeScript utilities.                                   |
| [`scripts/`](./scripts)             | Repository and GitHub workflow automation scripts.                                                 |
| [`secrets/`](./secrets)             | SOPS-encrypted host and user secrets.                                                              |

## Published Flake Outputs

<details open>
<summary><strong>Modules</strong></summary>

```nix
inputs.euvlok.nixosModules.default
inputs.euvlok.darwinModules.default
inputs.euvlok.homeModules.default
inputs.euvlok.homeModules.os
```

The same modules are also exposed under `flake.modules` for newer consumers.

</details>

<details>
<summary><strong>Configurations</strong></summary>

```text
nixosConfigurations:
  blind-faith
  nanachi
  null
  nyx
  unsigned-int8
  unsigned-int16
  unsigned-int32
  unsigned-int64

darwinConfigurations:
  FlameFlags-Mac-mini
  faputa
  unsigned-int8

homeConfigurations:
  ashuramaruzxc
  bigshaq9999
  lay-by
  sm-idk
```

</details>

<details>
<summary><strong>Apps and packages</strong></summary>

```text
auto-rebase
browser-extension-update
nvidia-prefetch
```

Each package is also exposed as a flake app, so it can be run with
`nix run .#auto-rebase`, `nix run .#browser-extension-update`, or
`nix run .#nvidia-prefetch`.

</details>

## Working Here

Enter the development environment:

```sh
nix develop
```

Install JavaScript dependencies when needed:

```sh
bun install
```

Run the main checks:

```sh
bun run check
bun test
```

Format the TypeScript workspace:

```sh
bun run format
```

Format Nix files through the flake formatter:

```sh
nix fmt
```

## Common Operations

Build or inspect a host:

```sh
nix build .#nixosConfigurations.nyx.config.system.build.toplevel
nix build .#darwinConfigurations.FlameFlags-Mac-mini.system
```

Run one of the local automation tools:

```sh
nix run .#auto-rebase
nix run .#browser-extension-update
nix run .#nvidia-prefetch
```

Work directly with the Bun scripts:

```sh
bun run github:check-workflows
bun run github:lint-workflows
bun run github:update-browser-extensions
bun run github:update-custom-packages
bun run github:update-trivial-flake-inputs
```

## Design Notes

EUVlok is built around a few preferences:

- Keep host files thin and push reusable behavior into modules.
- Separate shared defaults from personal taste wherever the boundary is useful.
- Treat automations as source code, with tests where the behavior can drift.
- Prefer explicit flake outputs over undocumented local conventions.
- Keep secrets encrypted and close to the configurations that consume them.

## Useful Nix Resources

| Resource                                                           | Why it is useful                                                                 |
| ------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| [nix.dev](https://nix.dev/)                                        | The best general-purpose on-ramp for modern Nix.                                 |
| [NixOS Wiki](https://wiki.nixos.org/wiki/NixOS_Wiki)               | Practical notes for services, hardware, and day-to-day system work.              |
| [Nixpkgs](https://github.com/NixOS/nixpkgs)                        | The source of truth for packages, modules, and patterns worth copying carefully. |
| [Nixpkgs manual](https://nixos.org/manual/nixpkgs/stable/)         | Package, override, and library documentation.                                    |
| [Home Manager options](https://home-manager-options.extranix.com/) | Searchable Home Manager option reference.                                        |
| [Noogle](https://noogle.dev/)                                      | Search for Nix functions and examples.                                           |
| [Devenv](https://devenv.sh/)                                       | Reproducible development shells with a friendly interface.                       |

## Credits

This repo borrows ideas, patterns, and taste from the wider Nix community. It
also uses the Catppuccin palette and footer art; see the
[Catppuccin project](https://github.com/catppuccin/catppuccin) for licensing
and assets.

<p align="center">
  <img
    alt=""
    src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/footers/gray0_ctp_on_line.svg?sanitize=true"
  />
</p>
