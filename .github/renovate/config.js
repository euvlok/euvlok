module.exports = {
  platform: "github",
  autodiscover: false,
  onboarding: false,
  requireConfig: "required",
  binarySource: "global",
  allowScripts: false,
  allowedEnv: ["GH_TOKEN", "GITHUB_TOKEN", "NIX_CONFIG"],
  allowedCommands: [
    "^euvlokRenovatePostUpgrade\\.ts (flake|determinate|linux-rt-upscaler|lsfg-vk|nvidia-driver|catppuccin-gtk)$",
  ],
  repositories: ["euvlok/euvlok"],
  secrets: { githubToken: process.env.RENOVATE_TOKEN || "" },
  customEnvVariables: {
    GH_TOKEN: "{{ secrets.githubToken }}",
    GITHUB_TOKEN: "{{ secrets.githubToken }}",
    NIX_CONFIG:
      "accept-flake-config = true\naccess-tokens = github.com={{ secrets.githubToken }}",
  },
};
