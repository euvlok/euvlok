<h1 align="center">EUVlok</h1>

<p align="center">
  <a href="https://github.com/euvlok/euvlok/actions/workflows/ci.yml">
    <img
      alt="CI status"
      src="https://img.shields.io/github/actions/workflow/status/euvlok/euvlok/ci.yml?branch=master&style=for-the-badge&label=ci&colorA=303446&colorB=a6d189"
    />
  </a>
  <a href="https://github.com/euvlok/euvlok/issues">
    <img
      alt="Open issues"
      src="https://img.shields.io/github/issues/euvlok/euvlok?style=for-the-badge&colorA=303446&colorB=ef9f76"
    />
  </a>
  <a href="LICENSE">
    <img
      alt="MIT license"
      src="https://img.shields.io/github/license/euvlok/euvlok?style=for-the-badge&colorA=303446&colorB=8caaee"
    />
  </a>
</p>

<p align="center">
  <a href="#working-on-the-configs"><kbd>Get started</kbd></a>
  &nbsp;&nbsp;
  <a href="#finding-things"><kbd>Explore the repo</kbd></a>
  &nbsp;&nbsp;
  <a href="#using-the-modules"><kbd>Use the modules</kbd></a>
</p>

---

Our NixOS, nix-darwin, and Home Manager configs. We share modules and keep each
person's machine settings in [`hosts/`](hosts/). These are the configs we use,
including personal defaults and encrypted secrets.

<table>
  <tr>
    <td align="center" valign="top" width="33%">
      <h3>NixOS</h3>
      <p>Linux system configs</p>
      <a href="modules/nixos/"><kbd>Browse NixOS modules</kbd></a>
    </td>
    <td align="center" valign="top" width="33%">
      <h3>nix-darwin</h3>
      <p>macOS system configs</p>
      <a href="modules/darwin/"><kbd>Browse Darwin modules</kbd></a>
    </td>
    <td align="center" valign="top" width="33%">
      <h3>Home Manager</h3>
      <p>Shells, editors, and desktop apps</p>
      <a href="modules/hm/"><kbd>Browse home modules</kbd></a>
    </td>
  </tr>
</table>

## Working on the configs

Enter the development shell with [devenv](https://devenv.sh/):

```sh
devenv shell
```

If it asks you to trust the checkout, run `devenv allow`. To format and check:

```sh
devenv tasks run devenv:treefmt:run
devenv test
```

The configs use
[Determinate Nix](https://docs.determinate.systems/determinate-nix/). Build each
host on its matching platform:

<details>
  <summary><strong>Build a NixOS host on Linux</strong></summary>

```sh
nix build .#nixosBuilds.blind-faith
```

`nixosBuilds` needs Determinate Nix's `parallel-eval` feature.

</details>

<details>
  <summary><strong>Build a nix-darwin host on macOS</strong></summary>

```sh
nix build .#darwinConfigurations.faputa.system
```

</details>

## Finding things

| Path                               | What's there                                       |
| ---------------------------------- | -------------------------------------------------- |
| [`hosts/`](hosts/)                 | Machine configs and personal profiles              |
| [`modules/`](modules/)             | Shared NixOS, nix-darwin, and Home Manager modules |
| [`flake-modules/`](flake-modules/) | Flake outputs and host definitions                 |
| [`packages/`](packages/)           | Local packages and the NVIDIA driver pin           |
| [`lib/`](lib/)                     | Helpers and overlays                               |
| [`secrets/`](secrets/)             | SOPS-encrypted secrets                             |

To list hosts, owners, platforms, and CI runners:

```sh
nix eval .#hostMetadata --json
```

CI uses the same inventory for its build matrix.

## Using the modules

Under `inputs.euvlok`, import the default module for your platform:

| Platform                               | Module                   |
| -------------------------------------- | ------------------------ |
| NixOS                                  | `nixosModules.default`   |
| nix-darwin                             | `darwinModules.default`  |
| Standalone Home Manager                | `homeModules.default`    |
| Home Manager under NixOS or nix-darwin | `homeModules.integrated` |

For integrated Home Manager, set `home-manager.useGlobalPkgs = true`. Individual
modules are available too; run `nix flake show` to browse them.

---

<p align="center">
  <sub>
    Made for our machines. Shared under the
    <a href="LICENSE">MIT license</a>
  </sub>
</p>
