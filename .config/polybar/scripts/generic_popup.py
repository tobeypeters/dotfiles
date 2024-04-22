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

""" generic_popup.py
    Description:
        Builds & displays a user defined popup menu.

    Arguments:
        --className, --class - Override the popup classname.
        --location, --loc - Location to display the popup.
        --items - Menu Items to display.
        --commands - Commands to execute.
        --menu_colors, --mc - Override the colors, of the popup menu.
                              Colors must be specified in hex format and
                              in the order: bg fg highlightbg highlightfg

    Usage:
        generic_popup.py --location "+0+18" --className "whatever_className" --items "Item 1" "sep" "Item 2" --commands "command1" "nop" "command2" --menu_colors "#242424" "#FFFFFF" "#FCB827"

    Notes:
        Location <"+x+y"> : "+0+18"
        Items and commands are stored in lists.  But, think of it as a dictionary:

        { 'Item1' : 'command1', 'Item2' : 'command2' }

        "sep" = Generate a menu Separator
        command "nop" = Don't execute a command for the associated item
"""

# Get a list of installed applications
#aptitude -F'%p' --no-gui --disable-columns search '?and(~i,!?section(libs), !?section(kernel), !?section(devel))'

from argparse import ArgumentParser, Namespace as arg_namespace
from my_helper import process_exec
from tkinter import Menu, RAISED, Tk
from typing import Any

parser = ArgumentParser()
parser.add_argument('--className', '--class', type=str, help='Override the popup classname.')
parser.add_argument('--location', '--loc',  type=str, help='Location to display the popup.')
parser.add_argument('--items', nargs='*', type=str, required=True, help='Menu Items to display.')
parser.add_argument('--commands', nargs='*', type=str, required=True, help='Commands to execute.')
parser.add_argument('--menu_colors', '--mc', nargs=4, type=str,
                     help='Override the colors, of the popup menu.  Colors must be specified in hex format and in the order: bg fg highlightbg highlightfg')
args: arg_namespace = parser.parse_args()

def dhc(hex_color):
    # Remove '#' if present and convert hex to RGB
    hex_color = hex_color.lstrip('#')
    rgb = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

    # Darken each component by 90%
    new_rgb = tuple(int(max(0, c * 0.1)) for c in rgb)

    # Convert RGB back to hex
    dark_hex_color = '#{:02x}{:02x}{:02x}'.format(*new_rgb)

    return dark_hex_color

def on_command(item: str, cmd : str = '') -> None:
    if cmd:
        process_exec(cmd)
    else:
        process_exec(f"notify-send 'generic_popup.py:' 'No command was supplied for\n`{item}`'")

my_w = Tk(className='tp_popup_menu' if not args.className else args.className)
my_w.geometry(f"0x0{'+0+19' if not args.location else args.location}")
my_w.update()

my_w.state("withdrawn")

popup_params: dict[str, Any] = { 'master' : my_w, 'relief' : RAISED, 'tearoff' : 0 }

if args.menu_colors:
    mc: list[str] = args.menu_colors

#    popup_params.update({'bg' : dhc(mc[1]), 'fg' : mc[1], 'activebackground' : mc[2], 'activeforeground' : mc[3] })
    popup_params.update({'bg' : mc[0], 'fg' : mc[1], 'activebackground' : mc[2], 'activeforeground' : mc[3] })

popup: Menu = Menu(**popup_params)

popup.bind('<FocusOut>', lambda e : my_w.destroy())

for i, c in zip(args.items, args.commands):
    if not i == '-':
        popup.add_command(label=f' {i}', command=lambda itm = i, cmd = c : on_command(itm, cmd))
    else:
        popup.add_separator()

popup.tk_popup(my_w.winfo_rootx(), my_w.winfo_rooty())

popup.wait_window()
