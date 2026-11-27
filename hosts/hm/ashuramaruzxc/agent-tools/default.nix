{
  config,
  lib,
  pkgs,
  ...
}:
let
  packages = pkgs.unstable or pkgs;
  astGrepSkillSource = pkgs.fetchFromGitHub {
    owner = "ast-grep";
    repo = "agent-skill";
    rev = "0613dc7f82bbfb3b557380b54726b92f73358460";
    hash = "sha256-HFZVX/UYsct8EMtkczBGJNr9RjjDz77zY6SHS1WlKkc=";
  };
  sharedSkills = {
    ast-grep = "${astGrepSkillSource}/ast-grep/skills/ast-grep";
    forgejo = ./skills/forgejo;
  };
  ansibleSkillsSource = pkgs.fetchFromGitHub {
    owner = "leogallego";
    repo = "ai-skills-ansible";
    rev = "91b05d8e1c2a1750dda2422ba65aaf44e9a92fb4";
    hash = "sha256-XslkkmmleYlPiEZaSi4cvtLOMmMVyZpIThwOm9mOXvo=";
  };
  ansibleSkillNames = [
    "ansible-docs"
    "ansible-good-practices"
    "ansible-new-collection"
    "ansible-new-ee"
    "ansible-new-molecule"
    "ansible-new-role"
    "ansible-zen"
  ];
  ansibleSkills = pkgs.runCommand "ansible-agent-skills" { } (
    lib.strings.concatMapStringsSep "\n" (name: ''
      mkdir -p "$out/${name}"
      cp -R ${ansibleSkillsSource}/${name}/skills/${name}/. "$out/${name}/"
      if [ -d ${ansibleSkillsSource}/${name}/references ]; then
        cp -R ${ansibleSkillsSource}/${name}/references "$out/${name}/references"
      fi
    '') ansibleSkillNames
  );
in
{
  imports = [ ./mcp.nix ];

  config = lib.modules.mkMerge [
    (lib.modules.mkIf config.programs.codex.enable {
      home.packages = [ packages.glab ];
      programs.codex.skills = sharedSkills // {
        glab = "${packages.glab.src}/internal/commands/skills/bundled/assets/glab";
      };

      home.file = lib.attrsets.genAttrs' ansibleSkillNames (name: {
        name = ".agents/skills/${name}";
        value.source = "${ansibleSkills}/${name}";
      });
    })
    (lib.modules.mkIf config.programs.claude-code.enable {
      programs.claude-code.skills = sharedSkills;
    })
    (lib.modules.mkIf config.programs.antigravity-cli.enable {
      programs.antigravity-cli.skills = sharedSkills;
    })
  ];
}
