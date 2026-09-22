{ euvlokInputs }:
{ ... }:
{
  imports = [ euvlokInputs.pared.darwinModules.default ];

  programs.pared = {
    enable = true;
    defaultState = false;
  };
}
