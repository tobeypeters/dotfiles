#!/usr/bin/env bash

: <<'LICENSE'
  The MIT License (MIT)
  Copyright (c) Tobey Peters
  See full license at: https://github.com/tobeypeters
LICENSE

: <<'DESCRIPTION'
  System Updater
DESCRIPTION

sudo apt update
echo ''
sudo aptitude full-upgrade --assume-yes
#sudo apt dist-upgrade -y
echo ''
#sleep 1000
polybar-msg action updater module_hide
