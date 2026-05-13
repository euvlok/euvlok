{
  pkgs,
  versionMappings,
  getLatestVersion,
  ...
}:
{
  packages = builtins.attrValues { inherit (pkgs.unstable) jdt-language-server gradle maven; };
  versionMap = versionMappings.java;
  defaultVersion = getLatestVersion versionMappings.java;
  vscode.extensions = [
    "oracle.oracle-java"
    "redhat.java"
    "vscjava.vscode-gradle"
    "vscjava.vscode-java-debug"
    "vscjava.vscode-java-dependency"
    "vscjava.vscode-java-test"
    "vscjava.vscode-maven"
    "vscjava.vscode-spring-initializr"
  ];
  vscode.settings."[java]" = {
    editor.formatOnPaste = true;
    editor.defaultFormatter = "esbenp.prettier-vscode";
    editor.formatOnSave = true;
  };
  zed.extensions = [
    "java"
    "java-eclipse-jdtls"
  ];
  zed.languages."Java" = {
    language_servers = [ "jdtls" ];
    formatter = "language_server";
    prettier.allowed = false;
  };
  zed.lsp.jdtls.binary.path = "jdtls";
}
