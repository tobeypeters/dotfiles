#!/usr/bin/env bash

: <<'LICENSE'
  The MIT License (MIT)
  Copyright (c) Tobey Peters
  See full license at: https://github.com/tobeypeters
LICENSE

: <<'DESCRIPTION'
  Change the keyboard lighting, based on system configuration.
DESCRIPTION

: <<'USAGE'
  #!/bin/bash
  # Usage: ckb-colors.sh <left> <middle> <right>
  # Accepts hex (ff69b4) or rgb(r,g,b)
USAGE

sleep 3

# Wait for wal to set colors (if using wal)
if [ -f ~/.cache/wal/colors.sh ]; then
    # Source the color file if it exists
    . ~/.cache/wal/colors.sh
    FG="$color15"  # Typically foreground color
    BG="$color0"   # Typically background color
else
    # Fallback colors if wal isn't used
    FG="#ffffff"   # White
    BG="#000000"   # Black
fi

# Try to set keyboard colors
if [ -e "/dev/input/ckb1/cmd" ]; then
    echo "active" > /dev/input/ckb1/cmd
    echo "rgb $FG $BG $FG" > /dev/input/ckb1/cmd
    sleep 0.5
    # Commit the changes
    echo "commit" > /dev/input/ckb1/cmd
fi
