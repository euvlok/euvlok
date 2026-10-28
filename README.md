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

Our NixOS, [ndw](https://github.com/4evy/ndw), and Home Manager configs. We
share modules and keep each person's machine settings in [`hosts/`](hosts/).
These are the configs we use, including personal defaults and encrypted secrets.

<table>
  <tr>
    <td align="center" valign="top" width="33%">
      <h3>NixOS</h3>
      <p>Linux system configs</p>
      <a href="modules/nixos/"><kbd>Browse NixOS modules</kbd></a>
    </td>
    <td align="center" valign="top" width="33%">
      <h3>ndw</h3>
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

</details>

<details>
  <summary><strong>Build an ndw host on macOS</strong></summary>

```sh
nix build .#darwinConfigurations.faputa.system
```

</details>

Darwin hosts require Apple Silicon and macOS 27 or newer. To switch from an
existing checkout:

```sh
nix run github:4evy/ndw -- switch --flake .#faputa
```

Subsequent switches can use `darwin switch --flake .#faputa`. The command builds
as your user and requests sudo only for activation.

On a fresh `unsigned-int8`, bootstrap its pinned Homebrew installation before
the first switch. Existing Homebrew installations migrate during activation.
The bootstrap preserves installed packages and backs up replaced Homebrew code
and taps:

```sh
nix build .#darwinConfigurations.unsigned-int8.config.system.build.homebrew-install -o result-homebrew
sudo ./result-homebrew
```

## Finding things

| Path                               | What's there                                |
| ---------------------------------- | ------------------------------------------- |
| [`hosts/`](hosts/)                 | Machine configs and personal profiles       |
| [`modules/`](modules/)             | Shared NixOS, ndw, and Home Manager modules |
| [`flake-modules/`](flake-modules/) | Flake outputs and host definitions          |
| [`packages/`](packages/)           | Local packages and the NVIDIA driver pin    |
| [`lib/`](lib/)                     | Helpers and overlays                        |
| [`secrets/`](secrets/)             | SOPS-encrypted secrets                      |

To list hosts, owners, platforms, and CI runners:

```sh
nix eval .#hostMetadata --json
```

CI uses the same inventory for its build matrix.

## Using the modules

Under `inputs.euvlok`, import the default module for your platform:

| Platform                        | Module                   |
| ------------------------------- | ------------------------ |
| NixOS                           | `nixosModules.default`   |
| ndw                             | `darwinModules.default`  |
| Standalone Home Manager         | `homeModules.default`    |
| Home Manager under NixOS or ndw | `homeModules.integrated` |

For integrated Home Manager, set `home-manager.useGlobalPkgs = true`. Individual
modules are available too; run `nix flake show` to browse them.

For Home Manager under ndw, also import `darwinModules.home-manager` instead of
Home Manager's nix-darwin module. The
[native integration](modules/darwin/home-manager.nix) uses ndw's activation
steps and user package profiles. Set `users.users.<name>.uid` for accounts
receiving packages through `home-manager.useUserPackages`, so ndw can validate
application ownership.

---

<p align="center">
  <sub>
    Made for our machines. Shared under the
    <a href="LICENSE">MIT license</a>
  </sub>
</p>
