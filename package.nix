{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
  makeDesktopItem,
  release,
}:
let
  inherit (release) version;
  launcher = stdenvNoCC.mkDerivation {
    pname = "horizon-launcher-unwrapped";
    inherit version;
    src = fetchurl {
      inherit (release) url sha256;
    };
    sourceRoot = ".";
    dontBuild = true;
    dontFixup = true; # The original ELF runs inside the FHS environment below.
    installPhase = ''
      runHook preInstall
      install -Dm755 horizon-launcher $out/bin/horizon-launcher
      runHook postInstall
    '';
  };
  desktop = makeDesktopItem {
    name = "horizon-launcher";
    desktopName = "Horizon";
    comment = "Horizon game launcher";
    exec = "horizon-launcher";
    categories = [ "Game" ];
    terminal = false;
  };
in
buildFHSEnv {
  pname = "horizon-launcher";
  inherit version;
  # The launcher downloads additional ELF executables (game, prepare, server).
  # A shared FHS environment also handles those without patching user data.
  targetPkgs =
    p: with p; [
      stdenv.cc.cc.lib
      # Native mods use the launcher's pinned Rust, but need a system C toolchain.
      stdenv.cc
      binutils
      pkg-config
      gnumake
      cmake
      ninja
      glibc.dev
      linuxHeaders
      alsa-lib.dev
      udev.dev
      openssl.dev
      zlib.dev
      zlib
      openssl
      curl
      cacert
      libxkbcommon
      libxcb
      libX11
      libXcursor
      libXi
      libXrandr
      libXext
      libXrender
      wayland
      libGL
      vulkan-loader
      alsa-lib
      libpulseaudio
      pipewire
      udev
      dbus
      fontconfig
      freetype
      dejavu_fonts
      xdg-utils
      bash
      coreutils
      procps
      python3
      jdk21
    ];
  multiPkgs = null;
  runScript = "${launcher}/bin/horizon-launcher";
  profile = ''
    export HORIZON_LAUNCHER_NO_SELF_UPDATE=1
    # Some development outputs (including zlib) put .pc files in share.
    export PKG_CONFIG_PATH="/usr/share/pkgconfig:$PKG_CONFIG_PATH"
  '';
  extraInstallCommands = ''
    mkdir -p $out/share
    ln -s ${desktop}/share/applications $out/share/applications
  '';
  passthru = {
    unwrapped = launcher;
  };
  meta = {
    description = "Horizon game launcher (official binary release)";
    homepage = "https://github.com/horizon-rust/horizon";
    license = lib.licenses.lgpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "horizon-launcher";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
