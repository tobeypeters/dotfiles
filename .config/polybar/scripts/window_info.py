#!/usr/bin/env python3

#	The MIT License(MIT)
#	Copyright(c), Tobey Peters, https://github.com/tobeypeters
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

# Gets the foreground windows' Application/classname, Title or both <default> of them and
# returns it to our polybar module.

# Arguments:
#
#       --application - We just want the application "classname" of the current foreground window.
#       --title - We just want the title of the current foreground window.
#       --len_title - Max length of the title, you want to display.
#
#       --application_colors - The Application will be displayed with the specified colors, both of which MUST be provided.
#       --title_colors - The Title will be displayed with the specified colors, both of which MUST be provided.

# Usage:
#
#       window_info.py --application --application_colors #ffffff #000000
#       window_info.py --title --title_colors #00ff00 #ffffff
#       window_info.py --application_colors #ffffff #000000 --title_colors #00ff00 #ffffff
#       window_info.py --title --len_title 50 --title_colors #00ff00 #ffffff

# args_gist:  https://gist.github.com/strager/e86e355cf8b9d60a0ff9b785506a34f9

# Add this to your i3 config : for_window [class="Cycle_switcher"] floating enable

from typing import List, Tuple
import i3ipc

from argparse import Action, ArgumentParser
from os import path

parser = ArgumentParser()
parser.add_argument('--application', action='store_true', help='Displays ONLY the foreground windows Application name.')
parser.add_argument('--title', action='store_true', help='Displays ONLY the foreground windows Title.')
parser.add_argument('--len_title', nargs=1, type=int, help='Max length of the title, you want to display.')
parser.add_argument('--application_colors', nargs=2, help='Override the background & foreground colors, of the displayed text.  Colors must be specified in hex format and in the order: bg fg')
parser.add_argument('--title_colors', nargs=2, help='Override the background & foreground colors, of the displayed text.  Colors must be specified in hex format and in the order: bg fg')
args = parser.parse_args()

def read_configuration() -> Tuple[List[str], List[str]]:
    # Defalut location: <script xxecution directory>/window_info.conf
    #
    # Format:
    #           <comment>   - First character needs to be a pound sign.
    #           <section>   - Either [ignore] or [exclude]
    #
    #                         [ignore]  - Classes you want window_info to completely ignore 100%.
    #                         [exclude] - Classes you want window_info to ignore, when displaying
    #                                     the title.  i.e. titles with valid "-" in them.
    #
    #           <classname> - Listed under one of the above mentioned sections.
    #                         Don't wrap it in quotes or anything.
    config_file = f'{path.dirname(path.realpath(__file__))}/window_info.conf'

    bi = []
    be = []

    if path.isfile(config_file):
        with open(config_file, 'r') as cfgFile:
            buffer = cfgFile.read().splitlines()

        bEx = bIg = False

        for b in buffer:
            if len(b) > 0:
                b = b.strip()

                if not b[0] == '#':
                    bl = b.lower()

                    if bl == '[ignore]':
                        bIg = True
                        bEx = False
                        continue

                    if bl == '[exclude]':
                        bEx = True
                        bIg = False
                        continue

                    if bIg: bi.append(b)
                    if bEx: be.append(b)

    return (bi, be)

prevInfo = ''

def get_window_info() -> str:
    # Strip the classname from window titles.  SEEMS LIKE the window title
    # is in the format f'{window_title}-{classname}'"
    # Is this true on all Distros?  I DO NOT KNOW
    # If not, comment out the methods' code and return title back.
    def stripClassFromTitle(title: str) -> str:
        if title == None: return ''

        idx: int = None

        strStrip = "-—"
        listStrip = list(strStrip)

        oddballs = [ '- Google Chrome' ]

        # Look for the the last occurrence.  On paper, going in reverse is faster.
        # But, not necessarily.
        # #for i, c in enumerate(reversed(title)):
        for i in range(len(title) - 1, 0, -1):
            if (title[i] in listStrip):
                # Try to make it smarter.  In case the window class has a dask in
                # it, don't truncate at the wrong spot.
                # This still won't get everything.
                if not title[i:].lower().find(str(focused_window.window_class).lower()) == -1 \
                    or title[i:] in oddballs:
                    idx = i
                    break

        return title if focused_window.window_class in exclude_titles or \
            title[idx:].strip(strStrip).lower() == \
            str(focused_window.window_class).strip(strStrip).lower() else title[:idx]

    def to_CamelCase(camelStr: str) -> str:
        return ''.join([t.title() for t in camelStr.split()])

    def colorizeText(formatStr: str, formatColors: List[str], bold: bool = False) -> str:
        # If you want bold to work, you need a font-2 def in you polybar config.
        return '' if len(formatStr) < 3 else \
            f"%{{B{formatColors[0]}}}%{{F{formatColors[1]}}}{'%{T3}' if bold else ''}{formatStr}{'%{T-}' if bold else ''}%{{B- F-}}"

    global prevInfo

    focused_window = i3.get_tree().find_focused()

    # Logic added to work in conjunction with cycle.py
    #if focused_window.window_class in [ 'Tp_popup_menu', 'spectacle', 'krunner' ]: return prevInfo
    if focused_window.window_class in ignore_classes: return prevInfo

    DESKTOPNAME = 'Finder'
    application_text = DESKTOPNAME
    title_text = DESKTOPNAME

    isContainer = focused_window.type == 'con'

    if not args.title:
        # Not a container, assume it's the desktop which has focus.
        #if focused_window.type == 'con':R

        if isContainer:
            application_text = '' if focused_window.window_class is None \
                                  else to_CamelCase(focused_window.window_class)
        else:
            title_text = ''

        application_text = f" {' ' if not application_text == '' else ''}{application_text.strip()}  "

        if (args.application_colors):
            application_text = colorizeText(application_text, args.application_colors, True)

        prevInfo = application_text

    if not args.application:
        if isContainer:
            title_text = stripClassFromTitle(focused_window.window_title)

            # Restrict the number of characters which are displayed.
            if args.len_title:
                l = args.len_title[0]
                if len(title_text) > l:
                    title_text = f'{title_text[0:l]}...'

        title_text = f"{'  ' if args.title else ''}{title_text.strip()}  "

        if (args.title_colors):
            title_text = colorizeText(title_text, args.title_colors)

        prevInfo = title_text

    if args.application or args.title: return prevInfo

    prevInfo = f'{application_text}{title_text}'

    return prevInfo

def on_window_title(s, e):
    print(get_window_info())

(ignore_classes, exclude_titles) = read_configuration()

i3 = i3ipc.Connection()

i3.on('window::focus', on_window_title)
i3.on('window::title', on_window_title)
i3.on('window::close', on_window_title)
i3.on('workspace', on_window_title)

on_window_title('', '')

i3.main()