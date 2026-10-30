{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  autoPatchelfHook,
  glibc,
  systemd,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "promtail";
  version = "3.6.11";

  # The official Linux release enables promtail_journal_enabled in its Makefile
  src = fetchurl {
    url = "https://github.com/grafana/loki/releases/download/v${finalAttrs.version}/promtail-linux-amd64.zip";
    hash = "sha256-+H1yNYUxzHAIojZnzGjMcm51EVzQiClQchXkm0ypIew=";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
  ];
  buildInputs = [ glibc ];
  # Journal support loads libsystemd with dlopen rather than a linked dependency
  runtimeDependencies = [ (lib.getLib systemd) ];

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 promtail-linux-amd64 "$out/bin/promtail"
    runHook postInstall
  '';

  meta = {
    description = "Promtail journal collector for unsigned-int64";
    homepage = "https://grafana.com/docs/loki/latest/send-data/promtail/";
    changelog = "https://github.com/grafana/loki/releases/tag/v${finalAttrs.version}";
    license = with lib.licenses; [
      agpl3Only
      asl20
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "promtail";
  };
})
