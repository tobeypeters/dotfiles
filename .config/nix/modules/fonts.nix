{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nerdfonts
  ];
  
  home.file.".local/share/fonts".source = fetchTarball {
    url = "https://github.com/AppleDesignResources/SanFranciscoFont/archive/refs/heads/master.zip";
    sha256 = "0fpfy884g81zsih0ldr8hj2jcxcm3xbw179zs0vbsqhsnq2p9wig";
  };
}
