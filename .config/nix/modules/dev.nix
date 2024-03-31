{ pkgs, ... }:

{
    home.packages = with pkgs; [
      vscode
      python3
      python311Packages.pip
      gcc
      rustc
      cargo
      #rustup
      meson
      ninja
    ];
}
