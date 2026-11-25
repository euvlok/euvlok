_: {
  programs.ssh.settings = {
    ictlab-frontend = {
      HostName = "ictlab.usth.edu.vn";
      User = "student10";
      Port = 22222;
    };
    ict14 = {
      HostName = "ict14";
      ProxyJump = "ictlab-frontend";
      User = "student10";
    };
  };
}
