def nix-build-file [
    file: string,
    args: string = "{}"
] {
    nix-build -E $"with import <nixpkgs> {}; callPackage ($file | path expand) ($args)"
}

def clean-roots [] {
    nix-store --gc --print-roots
    | lines
    | where { |line| $line !~ '^(/nix/var|/run/\w+-system|\{|/proc)' }
    | where { |line| $line !~ '\b(home-manager|flake-registry\.json)\b' }
    | parse --regex '^(?P<path>\S+)'
    | get path
    | each { |path| ^unlink $path }
}

def now [] { date now | format date "%H:%M:%S" }
def nowdate [] { date now | format date "%d-%m-%Y" }
def nowunix [] { date now | format date "%s" }
def xdg-data-dirs [] { echo $env.XDG_DATA_DIRS | str replace -a : "\n" | lines }

def to-mp4 [path: path] { 
    let stem = ($path | path parse | get stem); 
    let output = $"($stem).mp4";
    ffmpeg -i $path -c:v copy -c:a copy -c:s copy -loglevel error $output
}

def to-png [path: path] {
    let stem = ($path | path parse | get stem);
    let output = $"($stem).png";
    magick $path $output
}

def to-jpg [path: path] {
    let stem = ($path | path parse | get stem);
    let output = $"($stem).jpg";
    magick $path $output
}

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
