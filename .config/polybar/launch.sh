#!/bin/bash
##!/usr/bin/env sh

export CPU_TDLE=$(for i in /sys/class/hwmon/hwmon*/temp*_input; do echo "$(<$(dirname $i)/name): $(cat ${i%_*}_label 2>/dev/null || echo $(basename ${i%_*})) $(readlink -f $i)"; done | grep k10temp | awk '{ print $3 }')

## Add this to your wm startup file.
# Terminate already running bar instances
killall -q polybar

# killall doesn't seem to kill the scripts started by the bar.
# So, the following ways work better
# kill $(ps aux | grep 'polybar' | awk '{print $2}')  >/dev/null 2>&1
# kill -9 $(pgrep -f 'polybar') >/dev/null 2>&1

polybar-msg cmd quit >/dev/null 2>&1

# Wait until the processes have been shut down
#while pgrep -u -x $UID polybar >/dev/null; do sleep 1; done
while pgrep -x polybar >/dev/null; do sleep 1; done

# Launch bar1 and bar2
polybar -c ~/.config/polybar/config.ini main-i3 &