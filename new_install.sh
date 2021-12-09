#!/bin/bash

sudo apt-add-repository ppa:cubic-wizard/release
sudo apt update

#sudo apt upgrade

sudo apt install -y lightdm

sudo apt install -y curl

# Cargo and Rust
# Rust : https://www.rust-lang.org/tools/install
curl https://sh.rustup.rs -sSf | sh
#sudo apt install -y cargo

sudo apt install -y meson
sudo apt install -y ninja-build
sudo apt install -y yarn
sudo apt install -y clang
sudo apt install -y nodejs
sudo apt install -y npm
sudo apt install -y python3
sudo apt install -y python3-pip
sudo apt install -y python3-tk

sudo apt install -y php
sudo apt install -y php-curl

# https://code.visualstudio.com/Download

# After setting up the git bare repository, go setup two-way auth on their site
sudo apt install -y git

sudo apt install -y build-essential cmake cmake-data libasound2-dev libcairo2-dev
sudo apt install -y libcurl4-openssl-dev libfontconfig1-dev libfreetype6-dev libjsoncpp-dev
sudo apt install -y libmpdclient-dev libnl-genl-3-dev libnotify-bin libpulse-dev i3-wm
sudo apt install -y libxcb1-dev libxcb-composite0-dev libxcb-cursor-dev libxcb-ewmh-dev
sudo apt install -y libxcb-icccm4-dev libxcb-image0-dev libxcb-randr0-dev libxcb-util0-dev
sudo apt install -y libxcb-xfixes0-dev libxcb-xkb-dev libxcb-xrm-dev libxcomposite-dev
sudo apt install -y libxft-dev libxinerama-dev libxtst-dev pkg-config python3-sphinx
sudo apt install -y python3-xcbgen x11proto-xinerama-dev xboxdrv xcb-proto
sudo apt install -y libstartup-notification0-dev

# i3: https://i3wm.org/
# i3ipc :
pip3 install i3ipc

sudo add-apt-repository ppa:o2sh/onefetch
sudo apt update -y
sudo apt install-y onefetch

pip3 install jedi-language-server
pip3 install keyboard
pip3 install mypy

# Convert python scripts to executables
pip3 install pyinstaller
# cd /path/to/your/program
# pyinstaller --onefile yourscript.py

# Expose localhost to internet"
# https://ngrok.com/

# Polybar: https://github.com/polybar/polybar

# alacritty : https://github.com/alacritty/alacritty/blob/master/INSTALL.md
#
# sudo update-alternatives --install /usr/bin/x-terminal-emualtor x-terminal-emulator /usr/local/bin/alacritty 10
# sudo update-alternatives --config x-terminal-emulator
# alacritty end

# sudo apt install -y composer
sudo apt install -y lxappearance
sudo apt install -y mc
sudo apt install -y ncdu
sudo apt install -y network-manager-gnome
# sudo apt install network-manager nm-applet
sudo apt install -y pavucontrol
# sudo apt install -y picom
sudo apt install -y policykit-desktop-privileges
sudo apt install -y policykit-1-gnome
# sudo apt install -y rofi
sudo apt install -y wmctrl
sudo apt install -y xdo
sudo apt install -y xdotool

sudo apt install -y audacious
sudo apt install -y apt-file
sudo apt install -y atop
sudo apt install -y cava

# Chrome : https://www.google.com/chrome/
# Chrome Extension: https://chrome.google.com/webstore/detail/enhanced-h264ify/omkfmpieigblcllmkgbflkikinpkodlk/related
# Chrome Extension: https everywhere
# Chrome Extension: Google pip
# chrome://flags: Can enable Vuncan, and other such things
# Go into settings and turn off hardware acceleration
# Chrome end

sudo apt install -y ckb-next
sudo apt install -y --no-install-recommends cubic
sudo apt install -y feh
sudo apt install -y gimp
sudo apt install -y gnome-shell-extension-autohidetopbar
#sudo apt install -y glances
sudo apt install -y htop

# sudo apt install -y software-properties-common
# sudo add-apt-repository -y ppa:team-xbmc/ppa
# sudo apt install -y kodi

# krunner : installed already with KDE : sudo apt install plasma-workspace

# if you don't want to use a ramdisk, change the fifo file location in mpd.conf accordingly.
# /tmp/mpd.fifo
sudo apt install -y mpd

sudo apt install -y mpc
sudo apt install -y neovim
# nyxt browser - https://nyxt.atlas.engineer/download
sudo apt install -y p7zip-full
sudo apt install -y piper
sudo apt install -y sonata

# Playstation controller install instructions, in 99-steam-controller-perms.rules
sudo apt install -y steam

sudo apt install -y tldr
# sudo apt install -y virtualbox
sudo apt install -y virt-manager
sudo apt install -y yad

sudo apt install -y --reinstall plasma-widgets-addons

curl https://baltocdn.com/i3-window-manager/signing.asc | sudo apt-key add -
sudo apt install apt-transport-https --yes
echo "deb https://baltocdn.com/i3-window-manager/i3/i3-autobuild/ all main" | sudo tee /etc/apt/sources.list.d/i3-autobuild.list
sudo apt update
sudo apt install -y i3

sudo snap install auto-cpufreq

# In case, you want a ramdisk
# Make sure /mnt/ram_disk exists first
# new_ram_disk    /mnt/ram_disk   tmpfs    nodev,nosuid,noexec,nodiratime,size=256M   0

# UUID=780AE4AC0AE46918 /media/tibegato/StorageDaemon/    auto nosuid,nodev,nofail,x-gvfs-show 0 0

# sudo fc-cache -f -v

# enable firewall
# setup timeshift

# sudo dpkg-query -Wf '${Installed-size}\t${Package}\n' | column -t

# sudo apt install -y install gnome-boxes

# Docker GUI : https://github.com/vv9k/dockeye

# Monodevelop :
# sudo apt install apt-transport-https dirmngr
# sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
# echo "deb https://download.mono-project.com/repo/ubuntu vs-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-vs.list
# sudo apt update
# sudo apt install -y monodevelop

# https://safing.io/portmaster/

# absurd-sql : https://github.com/jlongster/absurd-sql

# calamari - https://calamares.io/

# ACTIVATE Windows 10 : https://www.reneelab.com/win10-activation-crack-free.html

# Share files with Samba : https://www.youtube.com/watch?v=LRh82RgD-Fc