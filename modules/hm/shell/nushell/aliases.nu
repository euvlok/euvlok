def nix-build-file [
    file: string,
    args: string = "{}"
] {
    nix-build -E $"with import <nixpkgs> {}; callPackage ($file | path expand) ($args)"
}

def clean-roots [] {
  nix-store --gc --print-roots
  | rg --no-filename -v '^(/nix/var|/run/\w+-system|\{|/proc)'
  | rg --no-filename -v 'home-manager|flake-registry\.json'
  | rg --no-filename -o -r '$1' '^(\S+)'
  | xargs -L1 unlink
}

def now [] { date now | format date "%H:%M:%S" }
def nowdate [] { date now | format date "%d-%m-%Y" }
def nowunix [] { date now | format date "%s" }
def xdg-data-dirs [] { echo $env.XDG_DATA_DIRS | str replace -a : "\n" | lines | enumerate }

def update [] {
    let nix_user = (whoami)
    let raw_host = (hostname)
    let is_darwin = (sys host | get name | str downcase | str contains "darwin")
    let nix_host = if $is_darwin {
        $raw_host | str replace -r '\.local$' ""
    } else {
        $raw_host
    }
    let flake_path = (readlink -f "/etc/nixos")
    let flake_attr = if $is_darwin {
        "darwinConfigurations"
    } else {
        "nixosConfigurations"
    }
    let github_username = (
        nix eval --raw --impure --expr (
            'let
              flake = builtins.getFlake "' + $flake_path + '";
              host = flake.' + $flake_attr + '."' + $nix_host + '";
              user = "' + $nix_user + '";
            in
              host.config.home-manager.users.''${user}.programs.git.userName'
        ) | str downcase | str trim
    )
    let matching_inputs = (
        nix eval --json --impure --expr (
            '(builtins.attrNames (builtins.getFlake "' + $flake_path + '").inputs)'
        )
        | from json
        | filter {|x| $x | str ends-with ("-" + $github_username)}
        | str join " "
    )
    nix flake update $matching_inputs --flake $flake_path
}
