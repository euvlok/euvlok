# set shell := ["nu", "-c"]

current-system := `nix eval --impure --raw --expr builtins.currentSystem`

# Hosts
DARWIN_HOSTS := "anons-Mac-mini"
NIXOS_HOSTS  := "blind-faith nanachi nyx"

# Format: "hostname:username" pairs (space-separated)
GITHUB_MAP := "anons-Mac-mini:donteatoreo blind-faith:lay-by nanachi:bigshaq9999 nyx:donteatoreo"

INPUTS_CMD := "nix eval --impure --expr 'builtins.attrNames (builtins.getFlake (toString ./.)).inputs' --json | jq -r '.[]'"

default:
    just --list

list-hosts:
    @if [ "{{os()}}" = "macos" ]; then \
        echo {{DARWIN_HOSTS}} {{NIXOS_HOSTS}}; \
    else \
        echo {{NIXOS_HOSTS}}; \
    fi

list-inputs:
    {{INPUTS_CMD}}

build user:
    @if [ {{os()}} = "macos" ]; then \
        darwin-rebuild switch --flake .#{{user}}; \
    else \
        nixos-rebuild switch --flake .#{{user}} --use-remote-sudo; \
    fi
