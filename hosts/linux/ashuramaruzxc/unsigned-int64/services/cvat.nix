{ config, ... }:
{
  users.groups = {
    cvat = {
      gid = config.users.users.cvat.uid;
    };
    nginx.members = [ "cvat" ];
  };
  users.users.cvat = {
    isSystemUser = true;
    group = "cvat";
    uid = 8765;
  };
}
