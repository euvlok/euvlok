{ pkgs, ... }:
{
  services = {
    samba-wsdd = {
      enable = true;
    };
    samba = {
      enable = true;
      package = pkgs.sambaFull;
      openFirewall = true;
      winbindd.enable = true;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          "server string" = "unsigned-int32";
          "netbios name" = "unsigned-int32";

          "hosts deny" = "0.0.0.0/0";
          "hosts allow" = [
            "192.168.1.0/24"
            "172.16.31.0/24"
            "127.0.0.1"
            "localhost"
          ];

          security = "user";
          invalidUsers = [ "root" ];
          "guest account" = "nobody";
          "map to guest" = "bad user";

          "load printers" = "yes";
          "printing" = "cups";
          "printcap name" = "cups";
        };
        printers = {
          "comment" = "All Printers";
          "path" = "/var/spool/samba";
          "public" = "yes";
          "browseable" = "yes";

          # to allow user 'guest account' to print.
          "guest ok" = "yes";
          "writable" = "no";
          "printable" = "yes";
          "create mode" = 700;
        };
        Public = {
          comment = "Public Directory";
          path = "/Shared";
          browseable = "yes";
          writeable = "yes";
          "inherit permissions" = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "guest only" = "no";
          "create mask" = "0644";
          "directory mask" = "0775";
          "directory mode" = "3770";
          "force directory mode" = "3770";
          "valid users" = "ashuramaru meanrin";
          "force user" = "ashuramaru";
          "force group" = "users";
        };

        marie = {
          comment = "Marie's personal directory";
          path = "/Users/marie";
          browseable = "yes";
          writeable = "yes";
          "inherit permissions" = "yes";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0770";
          "valid users" = "ashuramaru";
          "force user" = "ashuramaru";
          "force group" = "ashuramaru";
        };

        alex = {
          comment = "Alex's personal directory";
          path = "/Users/alex";
          browseable = "yes";
          "read only" = "no";
          writeable = "yes";
          "create mask" = "0644";
          "directory mask" = "0775";
          "valid users" = "meanrin";
          "force user" = "meanrin";
          "force group" = "meanrin";
        };

        "Marie's public directory" = {
          path = "/Users/marie/Public";
          browseable = "yes";
          writeable = "yes";
          "inherit permissions" = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "guest only" = "no";
          "force user" = "ashuramaru";
          "force group" = "ashuramaru";
          "directory mode" = "3770";
          "force directory mode" = "3770";
        };

        "Alex's public directory" = {
          path = "/Users/alex/Public";
          browseable = "yes";
          writeable = "yes";
          "inherit permissions" = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "guest only" = "no";
          "force user" = "meanrin";
          "force group" = "meanrin";
          "directory mode" = "3770";
          "force directory mode" = "3770";
        };

        timemachine = {
          comment = "Apple's Timemachine backups";
          path = "/var/lib/backup/tm-backup";
          public = "no";
          writeable = "yes";
          "read only" = "no";
          "security mask" = "0775";
          "create mask" = "0775";
          "directory mask" = "0775";
          "valid users" = "ashuramaru meanrin";
          "force user" = "backup";
          "force group" = "users";
          "fruit:aapl" = "yes";
          "fruit:time machine" = "yes";
          "vfs objects" = "catia fruit streams_xattr";
        };
      };
    };
  };
  users.users.backup = {
    isSystemUser = true;
    home = "/var/lib/backup";
    initialHashedPassword = "";
    extraGroups = [ "users" ];
    group = "backup";
  };
  users.groups.backup = { };
  systemd.tmpfiles.rules = [ "d /var/spool/samba 1777 root root -" ];
}
