_: {
  programs.ssh.extraConfig = ''
    Host ictlab-frontend
    	Hostname ictlab.usth.edu.vn
    	User student10
    	Port 22222

    Host ict14
    	Hostname ict14
    	ProxyJump ictlab-frontend
    	User student10
  '';
}
