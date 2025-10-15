{ }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = "{ x = r5, y = 5 }";
      };
      terminal = {
        shell = "alacritty";
      };
    };
  };
}
