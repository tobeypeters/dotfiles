#!/usr/bin/env python3

#   The MIT License(MIT)
#   Copyright(c), Tobey Peters, https://github.com/tobeypeters
#	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
#	and associated documentation files (the "Software"), to deal in the Software without restriction,
#	including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
#	and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
#	subject to the following conditions:
#	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
#	LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import os
import subprocess
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--menu_colors', nargs=3, help='Override the colors, of the sysmenu popup menu.  Colors must be specified in hex format and in the order: bg fg highlightcolor')

args = parser.parse_args()

items = [ "About This Computer...", "sep", "System Preferences...", \
    "App Store...", "sep", "System Monitor...  Ctrl +  + Del", \
    "sep", "Restart", "Shutdown", "Log Out" ]

commands = [ "gnome-control-center info-overview", "nop", "gnome-control-center info-overview", "snap-store", \
    "nop", "gnome-system-monitor", "nop", "systemctl reboot", "systemctl poweroff", "i3-msg exit" ]

itms = ''
cmds = ''

for i in items:
    itms += f"'{i}' "
for i in commands:
    cmds += f"'{i}' "

path = os.path.dirname(os.path.realpath(__file__))

command = f"{path}/generic_popup.py --width 29 --className 'tp_popup_menu' --items {itms}--commands {cmds}"

if args.menu_colors:
    mc = args.menu_colors
    command = f"{command}--menu_colors '{mc[0]}' '{mc[1]}' '{mc[2]}'"

subprocess.Popen(command, shell=True)