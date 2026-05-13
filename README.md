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
    <a href="#quick-start">Quick Start</a>
    ·
    <a href="#host-map">Host Map</a>
    ·
    <a href="#published-flake-outputs">Flake Outputs</a>
    ·
    <a href="#working-here">Working Here</a>
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
    <a href="https://github.com/euvlok/euvlok">
      <img alt="License" src="https://img.shields.io/github/license/euvlok/euvlok?style=for-the-badge&colorA=303446&colorB=8caaee">
    </a>
  </p>
</div>

---

<table align="center">
  <tr>
    <th>Systems</th>
    <th>Dotfiles</th>
    <th>Modules</th>
    <th>Tooling</th>
  </tr>
  <tr>
    <td>NixOS, nix-darwin, and standalone Home Manager.</td>
    <td>Chezmoi-managed user files, templates, and scripts.</td>
    <td>Reusable Nix layers for hosts, homes, services, shells, and themes.</td>
    <td>Bun/TypeScript automation for updates, CI, and local maintenance.</td>
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

> [!NOTE]
> EUVlok is a living configuration repo. Treat it as a map of useful patterns,
> not a drop-in installer for someone else's machine.

> [!IMPORTANT]
> Files under [`secrets/`](./secrets) are SOPS-encrypted and intentionally live
> beside the hosts that consume them.

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

## Quick Start

<table>
  <tr>
    <th>I want to...</th>
    <th>Run this</th>
  </tr>
  <tr>
    <td>Enter the development shell</td>
    <td>
      <pre><code>nix develop</code></pre>
    </td>
  </tr>
  <tr>
    <td>Build a NixOS host</td>
    <td>
      <pre><code>nix build .#nixosConfigurations.nyx.config.system.build.toplevel</code></pre>
    </td>
  </tr>
  <tr>
    <td>Build a nix-darwin host</td>
    <td>
      <pre><code>nix build .#darwinConfigurations.FlameFlags-Mac-mini.system</code></pre>
    </td>
  </tr>
  <tr>
    <td>Inspect a standalone Home Manager config</td>
    <td>
      <pre><code>nix eval .#homeConfigurations.bigshaq9999.config.home.username</code></pre>
    </td>
  </tr>
  <tr>
    <td>Run a local automation tool</td>
    <td>
      <pre><code>nix run .#auto-rebase</code></pre>
    </td>
  </tr>
</table>

## Host Map

| Output                | Owner           | Platform   | Entrypoint                                                                                                       |
| --------------------- | --------------- | ---------- | ---------------------------------------------------------------------------------------------------------------- |
| `blind-faith`         | `lay-by`        | NixOS      | [`hosts/linux/lay-by/hushh/default.nix`](./hosts/linux/lay-by/hushh/default.nix)                                 |
| `nanachi`             | `bigshaq9999`   | NixOS      | [`hosts/linux/bigshaq9999/nanachi/default.nix`](./hosts/linux/bigshaq9999/nanachi/default.nix)                   |
| `null`                | `sm-idk`        | NixOS      | [`hosts/linux/sm-idk/null/flake.nix`](./hosts/linux/sm-idk/null/flake.nix)                                       |
| `nyx`                 | `flameflag`     | NixOS      | [`hosts/linux/flameflag/nyx/default.nix`](./hosts/linux/flameflag/nyx/default.nix)                               |
| `unsigned-int16`      | `ashuramaruzxc` | NixOS      | [`hosts/linux/ashuramaruzxc/unsigned-int16/default.nix`](./hosts/linux/ashuramaruzxc/unsigned-int16/default.nix) |
| `unsigned-int32`      | `ashuramaruzxc` | NixOS      | [`hosts/linux/ashuramaruzxc/unsigned-int32/default.nix`](./hosts/linux/ashuramaruzxc/unsigned-int32/default.nix) |
| `unsigned-int64`      | `ashuramaruzxc` | NixOS      | [`hosts/linux/ashuramaruzxc/unsigned-int64/default.nix`](./hosts/linux/ashuramaruzxc/unsigned-int64/default.nix) |
| `FlameFlags-Mac-mini` | `flameflag`     | nix-darwin | [`hosts/darwin/flameflag/flame/default.nix`](./hosts/darwin/flameflag/flame/default.nix)                         |
| `faputa`              | `bigshaq9999`   | nix-darwin | [`hosts/darwin/bigshaq9999/nanachi/default.nix`](./hosts/darwin/bigshaq9999/nanachi/default.nix)                 |
| `unsigned-int8`       | `ashuramaruzxc` | nix-darwin | [`hosts/darwin/ashuramaruzxc/unsigned-int8/default.nix`](./hosts/darwin/ashuramaruzxc/unsigned-int8/default.nix) |

Standalone Home Manager outputs are exposed for `ashuramaruzxc`, `bigshaq9999`,
`lay-by`, and `sm-idk`.

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
