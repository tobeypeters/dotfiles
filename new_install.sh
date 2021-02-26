#!/bin/bash

#sudo touch /etc/default/google-chrome

#sudo apt upgrade
#sudo apt update

sudo apt install -y cargo
sudo apt install -y meson
sudo apt install -y ninja-build
sudo apt install -y yarn
sudo apt install -y clang
sudo apt install -y python3-tk

#sudo apt install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev python3
#sudo apt install -y python3-pip

#sudo snap install --classic code # or code-insiders

# Rust start
#curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
#snap install rustup
#rustup override set stable
#rustup update stable
# Rust end

#sudo apt install -y git

sudo apt install -y ckb-next
sudo apt install -y xdo
sudo apt install -y xdotool
sudo apt install -y neovim
sudo apt install -y sonata

# if you don't want to use a ramdisk, change the fifo file location in mpd.conf accordingly.
# /tmp/mpd.fifo
sudo apt install -y mpd

sudo apt install -y mpc
sudo apt install -y feh
sudo apt install -y htop

#pip3 install i3ipc

sudo apt install -y lightdm

# alacritty start
#cd ~/Downloads/
#git clone https://github.com/alacritty/alacritty.git
#cd alacritty/
#cargo build --release
#cargo install alacritty
#cp /home/tibegato/.cargo/bin/alacritty /usr/local/bin/
# sudo update-alternatives --install /usr/bin/x-terminal-emualtor x-terminal-emulator /usr/local/bin/alacritty 10
# sudo update-alternatives --config x-terminal-emulator
# alacritty end

#cd ~/Downloads/
#git clone https://github.com/tobeypeters/.dotfiles.git
#git clone https://github.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist.git

sudo apt install -y lxappearance
sudo apt install -y pavucontrol
sudo apt install -y rofi

sudo apt install -y network-manager-gnome

#sudo fc-cache -f -v

sudo apt intall -y xboxdrv
sudo apt install -y libnotify-bin

sudo apt install -y gimp

sudo apt install -y policykit-desktop-privileges
sudo apt install -y policykit-1-gnome

sudo apt install -y virtualbox

sudo apt install -y tldr

sudo apt install -y p7zip-full
sudo apt install -y cava

sudo apt install -y wmctrl

sudo add-apt-repository ppa:tiheum/equinox
sudo apt-get update && sudo apt-get install faenza-icon-theme

sudo apt install -y build-essential git cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev
sudo apt install -y libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev i3-wm libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libnl-genl-3-dev

#In case, krunner is running
# sudo apt install plasma-workspace

# enable firewall
# setup timeshift
# https://code.visualstudio.com/docs/setup/linux

# Chrome Extension: https://chrome.google.com/webstore/detail/enhanced-h264ify/omkfmpieigblcllmkgbflkikinpkodlk/related
# Chrome Extension: https everywhere
# Chrome Extension: Google pip

# chrome://flags: Can enable Vuncan, and other such things

# UUID=780AE4AC0AE46918 /media/tibegato/StorageDaemon/    auto nosuid,nodev,nofail,x-gvfs-show 0 0

# In case, you want a ramdisk
# Make sure /mnt/ram_disk exists first
# new_ram_disk    /mnt/ram_disk   tmpfs    nodev,nosuid,noexec,nodiratime,size=256M   0

# sudo dpkg-query -Wf '${Installed-size}\t${Package}\n' | column -t