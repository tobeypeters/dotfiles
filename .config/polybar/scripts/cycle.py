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

""" cycle.py, inspired by, https://gist.github.com/elundmark
    Description:
        Allows you to:
            * 'cycle' through your app windows, one by one, forward or backwards
            * Swap the contents of one window with another or
            * Display a popup menu which contains a list of all your windows.
              You can then select one and it'll switch to it.
        Uses generic_popup.py tp actually build it and display it.

    Arguments:
        --onlyclass, --oc - Filter visible windows, by the specified classname
        --menu_colors, --mc - Override the colors, of the switcher popup menu.
                              Colors must be specified in hex format and in the
                              order: bg fg highlightcolor

   i3 Sample key bindings:
                        bindsym $mod+Tab nop window next
                        bindsym $mod+Shift+Tab nop window prev
                        bindsym $mod+Ctrl+Tab nop window selector
                        bindsym $mod+Shift+a nop window swap
"""
from argparse import ArgumentParser, Namespace as arg_namespace
from i3ipc import connection as i3_con, events as i3_events
from json import  loads
from my_helper import gen_path_file, output_check, process_exec
from re import split
from typing import Any, Optional, Union, cast

parser: ArgumentParser = ArgumentParser()
parser.add_argument('--onlyclass', '--oc', nargs=1, type=str, help='Filter visible windows, by the specified classname.')
parser.add_argument('--menu_colors', '--mc', nargs=4, type=str, help='Override the colors, of the switcher popup menu.  Colors must be specified in hex format and in the order: bg fg highlightcolor')
args: arg_namespace = parser.parse_args()

i3: i3_con = i3_con.Connection()

"""import logging
logfile='/home/tibegato/app.log'
logging.basicConfig(filename=logfile, level=logging.INFO)
with open(logfile, 'w'):
    pass
for w in windows:
    logging.info(w)
"""

windows: list[int] = []
switcher: dict[int, str] = {}

ignore: list[str] = ["Polybar"]

def fill_nodes(f: str) -> None:
    def filler_up(tree: Optional[dict[str, Any]] = None):
        node_buffer = [l for ws in i3.get_tree().workspaces()
                       for l in ws if l.type == 'con' and
                       (not args.onlyclass or l.window_class == args.onlyclass[0])
                      ]

        for n in node_buffer:
            if f == 'switcher':
                switcher[n.window] = n.name
            else:
                if not n.window in windows:
                    windows.append(n.window)

        return {}

    filler_up()

def switch_window(c: i3_con.Connection, e: i3_events.BindingEvent) -> None:
    wc: int = len(windows)

    if wc > 0:
        focusedID: int = i3.get_tree().find_focused().window or windows[wc - 1]

        binding_cmd: str = e.ipc_data['binding']['command']
        if binding_cmd in commands:
            if binding_cmd in [commands[0], commands[1]]:

                """#Can't use starts-----------------------------------
                #This only cycles the current workspace.  I want it, to cycle apps
                #on all workspaces.
                if binding_cmd == commands[0]:
                    process_exec(f'i3-msg focus next')
                else:
                    process_exec(f'i3-msg focus prev')
                return
                -----Can't use ends-----------------------------------"""

                # We're tabbing forward or backward
                focus_idx: int = (
                                    (windows.index(focusedID) if focusedID > 0 else 0) +
                                    (1 if (binding_cmd == commands[0]) else -1)
                                 ) % wc

                i3.command(f'[id="{windows[focus_idx]}"] focus')

            if binding_cmd == commands[2]:
                fill_nodes('switcher')

                if switcher:
                    # Is the program a terminal?  If so, what's running in it?
                    def get_terminal_program(p_id: int, p_name: str) -> str:
                        """
                        p = subprocess.Popen(f'pgrep -P {piid}', shell=True, stdout=subprocess.PIPE)
                        result = p.communicate()[0].decode(encoding="utf-8", errors="ignore")
                        program = subprocess.Popen(f'ps -o comm= {piid}', shell=True)
                        xprop -id 0x3c00002 _NET_WM_PID | awk '/_NET_WM_PID\(CARDINAL\)/{print $NF}'
                        return hex(focused_window.window)

                        To make a your terminal window update it's title, you can
                        add something like this, to your .bashrc:

                            trap 'printf "\033]0;%s\007" "${BASH_COMMAND//[^[:print:]]/}"' DEBUG

                            IDK ... You can try it out & see if you like it. It essentially only shows
                            the last command you ran.
                        """

                        # Currently supported terminals.  Please ... add any missing ones.
                        if p_name.lower() in ['x-terminal-emulator', 'alacritty', 'kitty',
                                            'urxvt', 'rxvt', 'termit', 'terminator', 'Eterm',
                                            'aterm', 'uxterm', 'xterm', 'gnome-terminal',
                                            'roxterm', 'xfce4-terminal', 'termite', 'lxterminal',
                                            'mate-terminal', 'terminology', 'st', 'qterminal',
                                            'lilyterm', 'tilix', 'terminix', 'konsole'
                                            ]:

                            result: str = process_exec(f"xprop -id {hex(p_id)} _NET_WM_PID | awk '/_NET_WM_PID\(CARDINAL\)/{{print $NF}}'", True)

                            if not result == '':
                                piid: str = ''

                                while True:
                                    result = process_exec(f'pgrep -P {result}', True)

                                    if not result == '':
                                        piid = result
                                    else:
                                        result = f"{process_exec(f'ps -o comm= {piid}', True)}"

                                        return f"*{''.join(split('[^a-zA-Z]*', result))}*"

                        return ''

                    menu_items: str = ''
                    menu_cmds: str = ''

                    for w_id, w_name in switcher.items():
                        menu_items += f"'{w_name} {get_terminal_program(w_id, w_name)}' "
                        menu_cmds += f"'xdotool windowactivate {w_id} focus' "
                        #menu_cmds += f"'i3-msg [id={w_id}] focus' "

                    menu_items = menu_items.rstrip()
                    menu_cmds = menu_cmds.rstrip()

                    switcher.clear()

                    c_args: str = f"--location +28+19 --className tp_popup_menu --items {menu_items} --commands {menu_cmds}"
                    command: str = gen_path_file('generic_popup.py', __file__, c_args)

                    if args.menu_colors:
                        mc: list[str] = args.menu_colors

                        command = f"{command} --menu_colors '{mc[0]}' '{mc[1]}' '{mc[2]}' '{mc[3]}'"

                    process_exec(command)

            if binding_cmd == commands[3] and container_focused():
                if swapID[0] == 0:
                    """ Mark the focused window.
                        Marks will only show, if you have a title bar.
                    """
                    marker(marker_id=focusedID)
                else:
                    """ Remove the mark from the focused window.
                        User might have changed their mind & don't
                        want to swap windows.
                    """
                    marker(prefix='un')

def marker(marker_id: int = 0, prefix: str = '') -> None:
    swapID[0] = marker_id
    process_exec(f"i3-msg {prefix}mark Swap_Window")

def container_focused() -> bool:
    # Make sure a app window "con" is focused and not the desktop "workspace".
    return i3.get_tree().find_focused().type == 'con'

def new_window(c: i3_con.Connection, e: i3_events.WindowEvent) -> None:
    if e.container.window_class not in ignore:
        windows.append(e.container.window)

def close_window(c: i3_con.Connection, e: i3_events.WindowEvent) -> None:
    windows.remove(e.container.window)

def focus_window(c: i3_con.Connection, e: i3_events.WindowEvent) -> None:
    if swapID[0] and container_focused():
        process_exec(f"i3-msg swap container with id {swapID[0]}") # Swap the containers
        process_exec(f"i3-msg [id={swapID[0]}] focus") # focus the container
        marker(prefix='un')

commands = ['nop window next', 'nop window prev', 'nop window selector', 'nop window swap']

swapID: list[int] = [0]

fill_nodes('')

#process_exec(f'spd-say {wc}')

i3.on('window::new', new_window)
i3.on('window::close', close_window)
i3.on('window::focus', focus_window)
i3.on('binding', switch_window)

i3.main()

process_exec(f"notify-send 'cycle.py:' 'Script has terminated ...'")
