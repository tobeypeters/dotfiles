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

#   Example:
#               generic_popup.py --location "+0+18" --width 20 --className "whatever_className" --items "Item 1" "sep" "Item 2" --commands "command1" "nop" "command2" --menu_colors "#242424" "#FFFFFF" "#FCB827"
#
#   Note:
#               Location <"+x+y"> : "+0+18"
#               Items and commands are stored in lists.  But, think of it as a dictionary:
#
#               { 'Item1' : 'command1', 'Item2' : 'command2' }
#
#               "sep" = Generate a menu Seperator
#               command "nop" = Don't execute a command for the associated item

from argparse import ArgumentParser
from subprocess import Popen
from tkinter import *

parser = ArgumentParser()
parser.add_argument('--className', help='Override the popup classname.')
parser.add_argument('--location', help='Location to display the popup.')
parser.add_argument('--width', type=int, help='Override the width of the popup.')
parser.add_argument('--items', nargs='*', help='Menu Items to display.')
parser.add_argument('--commands', nargs='*', help='Commands to execute.')
parser.add_argument('--menu_colors', nargs=4, help='Override the colors, of the popup menu.  Colors must be specified in hex format and in the order: bg fg highlightbg highlightfg')

args = parser.parse_args()

def onclose(evt):
    my_w.destroy()

def onselect(evt):
    # We want to skip over separater lines
    # NOTE : Really ... it took this much code?  Killing me tkinter.
    global prevIDX

    nextIDX = idx = my_listbox.curselection()[0]

    if args.commands[idx] == 'nop':
        nextIDX = max(nextIDX + (1 if nextIDX > prevIDX else -1), 0)

        my_listbox.selection_clear(0, END)
        my_listbox.select_set(nextIDX)
        my_listbox.activate(nextIDX)

    prevIDX = nextIDX

    return

def onexecute(evt):
    command = args.commands[my_listbox.curselection()[0]]

    if not command == 'nop':
        Popen(command, shell=True)
        onclose('')

prevIDX = 0

sc = len(args.items)

w = 0
if args.width:
    w = args.width
else:
    for i in range(sc):
        w = max(w, len(args.items[i]))

sep = ''
for i in range(w):
    sep += '-'

l = '+2+20' if not args.location else args.location

my_w = Tk(className='tp_popup_menu' if not args.className else args.className)
my_w.geometry(l)

my_frame = Frame(my_w, borderwidth=1, highlightbackground="#000000", highlightcolor="#000000", highlightthickness=1, relief=RAISED)
my_frame.pack()

listbox_params = { 'master' : my_frame, 'bd' : 0, 'width' : w, 'height' : sc, 'relief' : RAISED }

if args.menu_colors:
    mc = args.menu_colors

    my_w.configure(bg=mc[0])
    my_frame.configure(highlightbackground=mc[3])
    my_frame.configure(highlightcolor=mc[2])

    listbox_params.update({'bg' : mc[0], 'fg' : mc[1], \
        'highlightcolor' : mc[0], 'selectbackground' : mc[2], 'selectforeground' : mc[3] })

my_listbox = Listbox(**listbox_params)
my_listbox.bind('<<ListboxSelect>>', onselect)
my_listbox.bind('<ButtonRelease-1>', onexecute)
my_listbox.bind('<Return>', onexecute)
my_listbox.bind('<Escape>', onclose)
my_listbox.bind("<FocusOut>", onclose)

my_listbox.bind("<Button-3>",lambda e, a=1, b=2: do_popup(e,a,b))

for i in range(sc):
    my_listbox.insert(END, f" {args.items[i] if args.items[i] != 'sep' else sep}" )

my_listbox.pack()

my_w.update()

my_w.geometry(f'{my_listbox.winfo_width() + 4}x{my_listbox.winfo_height() + 4}')

my_listbox.focus()
my_listbox.select_set(0)

my_w.mainloop()