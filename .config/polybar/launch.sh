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

sleep 1

# Launch cycle.py - Doing it here, cause colors don't get updated correctly.  Using pywal now.
color0=$(xrdb -query | awk '/color0:/ {print $2; exit}')
color1=$(xrdb -query | awk '/color1:/ {print $2; exit}')
$~/.config/polybar/scripts/cycle.py --menu_colors ${color0} ${color1} ${color1} ${color0} & disown

# Launch main-i3 bar
polybar -c ~/.config/polybar/config.ini main-i3 2>&1 | tee -a /mnt/ram_disk/polybar.log & disown