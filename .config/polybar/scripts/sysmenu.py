#!/usr/bin/env python3

""" The MIT License(MIT)
    Copyright(c), Tobey Peters, https://github.com/tobeypeters
	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the "Software"), to deal in the Software without restriction,
	including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
	subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
	LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""

""" sysmenu.py
    Description:
        Diplays a user defined system menu.
        Uses generic_popup.py tp actually build it and display it.

    Arguments:
        --menu_colors', '--mc' - Override the colors, of the sysmenu popup menu.
                                 Colors must be specified in hex format and in
                                 the order: bg fg highlightbg highlightfg
"""

from argparse import ArgumentParser, Namespace as arg_namespace
from my_helper import process_exec
from pathlib import Path

parser: ArgumentParser = ArgumentParser()
parser.add_argument('--menu_colors', '--mc', nargs=4, type=str, help='Override the colors, of the sysmenu popup menu.  Colors must be specified in hex format and in the order: bg fg highlightbg highlightfg')
args: arg_namespace = parser.parse_args()

items: str = "'About This Computer...' '-' 'System Preferences...' 'App Store...' 'Discover ...' '-' 'System Monitor...  Ctrl +  + Del' '-' 'Restart' 'Shutdown' 'Log Out'"
commands: str = "'gnome-control-center info-overview' '-' 'gnome-control-center info-overview' 'snap-store' 'plasma-discover' '-' 'gnome-system-monitor' '-' 'systemctl reboot' 'systemctl poweroff' 'i3-msg exit'"

command: str = f"{Path.joinpath(Path(__file__).parent, 'generic_popup.py')} --className 'tp_popup_menu' --items {items} --commands {commands}"

if args.menu_colors:
    mc: list[str] = args.menu_colors
    command = f"{command} --menu_colors '{mc[0]}' '{mc[1]}' '{mc[2]}' '{mc[3]}'"

process_exec(command)
