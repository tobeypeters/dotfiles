{ config, pkgs, nixpkgs, ... }:

{
  imports = [
    ~/modules/dev.nix
    ~/modules/rice.nix
    ~/modules/fonts.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "tibegato";
  home.homeDirectory = "/home/tibegato";  
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
