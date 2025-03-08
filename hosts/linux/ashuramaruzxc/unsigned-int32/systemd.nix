{ pkgs, path, ... }:
let
  generate_uuid = pkgs.stdenv.mkDerivation {
    pname = "assign_uuid";
    version = "3.11";

    buildInputs = [ pkgs.makeWrapper ];

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      makeWrapper ${pkgs.python3Packages.python.interpreter} $out/bin/assign_uuid \
        --set PYTHONPATH "$PYTHONPATH:${path + /src/generateuuid.py}" \
        --add-flags "-O ${path + /src/generateuuid.py}" \
    '';
  };
  generate_md5 = pkgs.stdenv.mkDerivation {
    pname = "assign_md5";
    version = "3.11";

    buildInputs = [ pkgs.makeWrapper ];

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      makeWrapper ${pkgs.python3Packages.python.interpreter} $out/bin/assign_md5 \
        --set PYTHONPATH "$PYTHONPATH:${path + /src/generatemd5.py}" \
        --add-flags "-O ${path + /src/generatemd5.py}" \
    '';
  };
  video2gif = pkgs.stdenv.mkDerivation {
    pname = "video2gif";
    version = "3.11";

    buildInputs = [ pkgs.makeWrapper ];

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      makeWrapper ${pkgs.python3Packages.python.interpreter} $out/bin/video2gif \
        --set PYTHONPATH "$PYTHONPATH:${path + /src/video2gif.py}" \
        --add-flags "-O ${path + /src/video2gif.py}" \
    '';
  };
in
{
  home.packages = [
    generate_uuid
    generate_md5
    video2gif
  ];
  systemd.user = {
    services."assign_uuid" = {
      Unit = {
        Description = "Run assign_uuid.service daily at 10am";
        Requires = [ "default.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${generate_uuid}/bin/assign_uuid /Users/marie/Downloads";
      };
    };
    services."assign_md5" = {
      Unit = {
        Description = "Run assign_md5.service daily at 10am";
        Requires = [ "default.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${generate_md5}/bin/assign_md5 /Users/marie/Pictures/d_PN";
      };
    };
    timers."assign_uuid" = {
      Unit = {
        Description = "Run assign_uuid.service daily at 10am";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Timer = {
        OnCalendar = "*-*-* 10:00:00";
        Unit = "assign_uuid.service";
        Persistent = true;
      };
    };
    timers."assign_md5" = {
      Unit = {
        Description = "Run assign_md5.service daily at 10am";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Timer = {
        OnCalendar = "*-*-* 10:00:00";
        Unit = "assign_md5.service";
        Persistent = true;
      };
    };
  };
}
