#!/bin/bash

: <<'LICENSE'
  The MIT License (MIT)
  Copyright (c) Tobey Peters
  See full license at: https://github.com/tobeypeters
LICENSE

: <<'DESCRIPTION'
  This is a horribly written script to click on the Network Manager
  Applet tray module, to bring up the menu.
DESCRIPTION

WID=$(xdotool search --onlyvisible --classname "nm-applet")

eval $(xdotool getwindowgeometry --shell $WID)

# I'm assuming the tray icons are 16 x 16.  Never assume things!!!!
# You can resize icons in Polybar and whatnot.
adjustX=$((X-16))

# Moving the mouse seems to "work"
xdotool mousemove $adjustX $Y

# Currently, click still doesn't seem to work.
xdotool click --window $WID 1
