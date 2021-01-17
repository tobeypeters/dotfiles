#!/usr/bin/env python3

#   The MIT License(MIT)
#   Original creator, who made the script which this was 
#   converted from, https://gist.github.com/elundmark
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

#   i3 Sample key bindings:
#                        bindsym $mod+Tab nop window next
#                        bindsym $mod+Shift+Tab nop window prev
#                        bindsym $mod+Ctrl+Tab nop window selector

import i3ipc

from argparse import ArgumentParser
from json import loads
from os import path
from re import split
from subprocess import call, check_output, Popen, PIPE
from tkinter import *

parser = ArgumentParser()
parser.add_argument('--onlyclass', nargs=1, help='Filter visible windows, by the specified classname.')
parser.add_argument('--menu_colors', nargs=3, help='Override the colors, of the switcher popup menu.  Colors must be specified in hex format and in the order: bg fg highlightcolor')
args = parser.parse_args()

i3 = i3ipc.Connection()

def fillNodes(f, s=''):
    def fillerUp(tree=None):
        if tree is None:
            tree = check_output(['i3-msg', '-t', 'get_tree'])
            tree = loads(tree.decode('utf8'))

        if tree['window_type'] == 'normal':
            if args.onlyclass and \
                (not 'class' in tree['window_properties'] or \
                tree['window_properties']['class'] != args.onlyclass[0]):
                    return []

            return [tree]

        for nodes in ['nodes', 'floating_nodes']:
            for node in tree[nodes]:
                for n in fillerUp(node):
                    if n['focused']:
                        focusedID[0] = n['window']
                    else:
                        if f == 'switcher':
                            switcher.append([n['window'], n['name']])
                            continue

                    if not n['window'] in windows:
                        windows.append(n['window'])

        return []

    fillerUp()

def switchWindow(a, e):
    wc = len(windows)

    if wc > 0:
        binding_cmd = e.ipc_data['binding']['command'].strip()
        if binding_cmd in commands:
            if binding_cmd == commands[0] or binding_cmd == commands[1]:
                if wc > 1:
                    try:
                        focusIDX = windows.index(focusedID[0]) + \
                        (1 if (binding_cmd == commands[0]) else -1)
                    except:
                        focusIDX = 0

                    wc -= 1
                    if focusIDX < 0: focusIDX = wc
                    if focusIDX > wc: focusIDX = 0

                call([ 'i3-msg', f'[id={windows[focusIDX]} ] focus']) # focus it using i3-msg

            if binding_cmd == commands[2]:
                fillNodes('switcher')

                if len(switcher) > 0: 
                    # Is the program a terminal?  If so, what's running in it?
                    def getTerminalProgram(wID: int, wname: str) -> str:
                        def pexec(command: str) -> str:
                            p = Popen(command, shell=True, stdout=PIPE, stderr=PIPE)
                            output, errors = p.communicate()
                            return output.decode(encoding="utf-8", errors="ignore")

                        #p = subprocess.Popen(f'pgrep -P {piid}', shell=True, stdout=subprocess.PIPE)
                        #result = p.communicate()[0].decode(encoding="utf-8", errors="ignore")
                        #program = subprocess.Popen(f'ps -o comm= {piid}', shell=True)
                        #xprop -id 0x3c00002 _NET_WM_PID | awk '/_NET_WM_PID\(CARDINAL\)/{print $NF}'
                        #return hex(focused_window.window) 

                        # To make a your terminal window update it's title, when you run & 
                        # only after you run a command ...You can add something like this,
                        # to your .bashrc:
                        #
                        #   trap 'printf "\033]0;%s\007" "${BASH_COMMAND//[^[:print:]]/}"' DEBUG
                        #
                        # IDK ... You can try it out & see if you like it.

                        # Currently supported terminals.  Please ... add any missing ones.
                        if wname.lower() in [ 'x-terminal-emulator', 'alacritty', 'urxvt', 'rxvt', 'termit', \
                        'terminator', 'Eterm', 'aterm', 'uxterm', 'xterm', 'gnome-terminal', \
                        'roxterm', 'xfce4-terminal', 'termite', 'lxterminal', 'mate-terminal', \
                        'terminology', 'st', 'qterminal', 'lilyterm', 'tilix', 'terminix', 'konsole' ]:
                            try:
                                result = pexec(f"xprop -id {hex(wID)} _NET_WM_PID | awk '/_NET_WM_PID\(CARDINAL\)/{{print $NF}}'")

                                if not result == '':
                                    piid = ''
                                    
                                    while True:
                                        result = pexec(f'pgrep -P {result}')

                                        if not result == '':
                                            piid = result
                                        else:
                                            result = f"{pexec(f'ps -o comm= {piid}')}"

                                            return f"*{''.join(split('[^a-zA-Z]*', result))}*"
                            except:
                                pass

                        return ''

                    cmds = itms = ''                   

                    for i in switcher:
                        itms += f"'{i[1]} {getTerminalProgram(i[0], i[1])} ' "
                        cmds += f"'i3-msg [id={i[0]}] focus' "
                    
                    switcher.clear()

                    _path = path.dirname(path.realpath(__file__))

                    command = f"{_path}/generic_popup.py --location '+28+20' --className 'tp_popup_menu' --items {itms}--commands {cmds}"

                    if args.menu_colors:
                        mc = args.menu_colors
                        command = f"{command}--menu_colors '{mc[0]}' '{mc[1]}' '{mc[2]}'"

                    Popen(command, shell=True)

            if binding_cmd == commands[3]:
                swapID[0] = focusedID[0]
                # Marks will only show, if you have a title bar.
                # I don't.  My windows have a 1px border.
                call(['i3-msg', 'mark Swap_Window'])

def closeFocusWindow(a, e):
    if e.container.window in windows:
        if e.ipc_data['change'] == 'close':            
            windows.remove(e.container.window)
        else:
            focusedID[0] = e.container.window
        
            if not swapID[0] == 0:
                # Make sure it's a valid container
                focused_window = i3.get_tree().find_focused()

                if focused_window.type == 'con':
                    call(['i3-msg', f'swap container with id {swapID[0]}'])
                
                call(['i3-msg', 'unmark Swap_Window'])

                swapID[0] = 0

commands = ['nop window next', 'nop window prev', 'nop window selector', 'nop window swap']

windows = []
switcher = []

focusedID = [0]
swapID = [0]

fillNodes('')

i3.on('window::new', fillNodes)
i3.on('window::close', closeFocusWindow)
i3.on('window::focus', closeFocusWindow)
i3.on('binding', switchWindow)

i3.main()

call(['notify-send', 'cycle.py:', 'Script has terminated ...'])