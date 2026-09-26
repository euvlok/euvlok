# EUVlok

<p>
  <a href="https://github.com/euvlok/euvlok/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/euvlok/euvlok/ci.yml?branch=master&style=for-the-badge&label=ci&colorA=303446&colorB=a6d189"></a>
  <a href="https://github.com/euvlok/euvlok/issues"><img alt="Open issues" src="https://img.shields.io/github/issues/euvlok/euvlok?style=for-the-badge&colorA=303446&colorB=ef9f76"></a>
  <a href="https://github.com/euvlok/euvlok"><img alt="License" src="https://img.shields.io/github/license/euvlok/euvlok?style=for-the-badge&colorA=303446&colorB=8caaee"></a>
</p>

Our NixOS, nix-darwin, and Home Manager configs. We share modules and keep each
person's machine settings in [`hosts/`](hosts/). These are the configs we use,
including personal defaults and encrypted secrets.

## Working on the configs

Enter the development shell with [devenv](https://devenv.sh/):

``` sh
devenv shell
```

If it asks you to trust the checkout, run `devenv allow`. To format and check:

``` sh
devenv tasks run devenv:treefmt:run
devenv test
```

Build a host on its matching platform:

``` sh
# Linux
nix build .#nixosBuilds.blind-faith

# macOS
nix build .#darwinConfigurations.faputa.system
```

The configs use [Determinate
Nix](https://docs.determinate.systems/determinate-nix/). `nixosBuilds` needs its
`parallel-eval` feature

## Finding things

| Path                               | What's there                                       |
| ---------------------------------- | -------------------------------------------------- |
| [`hosts/`](hosts/)                 | Machine configs and personal profiles              |
| [`modules/`](modules/)             | Shared NixOS, nix-darwin, and Home Manager modules |
| [`flake-modules/`](flake-modules/) | Flake outputs and host definitions                 |
| [`packages/`](packages/)           | Local packages and the NVIDIA driver pin           |
| [`lib/`](lib/)                     | Helpers and overlays                               |
| [`secrets/`](secrets/)             | SOPS-encrypted secrets                             |

Run `nix eval .#hostMetadata --json` to list hosts, owners, platforms, and CI
runners. CI uses the same inventory for its build matrix.

## Using the modules

Under `inputs.euvlok`, import `nixosModules.default`, `darwinModules.default`,
or `homeModules.default`. Individual modules are available too; run
`nix flake show` to browse them.

For Home Manager under NixOS or nix-darwin, use `homeModules.integrated` with
`home-manager.useGlobalPkgs = true`. Use `homeModules.default` for standalone
Home Manager.
