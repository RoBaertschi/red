# ml2 sw=2 ts=2 sts=2
{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.llvmPackages.bintools
    pkgs.pkg-config
    pkgs.raylib
    pkgs.odin
    pkgs.ols
    pkgs.alsa-lib
    pkgs.lldb
    pkgs.libGL
    pkgs.xorg.libX11
    pkgs.xorg.libX11.dev
    pkgs.xorg.libXcursor
    pkgs.xorg.libXi
    pkgs.xorg.libXinerama
    pkgs.xorg.libXrandr
    pkgs.glfw
  ];
    shellHook = ''
        export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
        '';
}
