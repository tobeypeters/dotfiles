#!/usr/bin/env python3

"""	The MIT License(MIT)
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

""" window_info.py
    Description:
        Gets the foreground windows' Application/classname, Title or both <default> of them and
        returns it to our polybar module.

    Arguments:
        --application - We just want the application "classname" of the current foreground window.
        --title - We just want the title of the current foreground window.
        --len_title, --lt - Max length of the title, you want to display.
        --application_colors, --ac - The Application will be displayed with the specified colors, both of which MUST be provided.
        --title_colors, --tc - The Title will be displayed with the specified colors, both of which MUST be provided.

    Usage:
        window_info.py --application --application_colors #ffffff #000000
        window_info.py --title --title_colors #00ff00 #ffffff
        window_info.py --application_colors #ffffff #000000 --title_colors #00ff00 #ffffff
        window_info.py --title --len_title 50 --title_colors #00ff00 #ffffff

    Notes:
        Add this to your i3 config : for_window [class="Cycle_switcher"] floating enable
"""

# args_gist:  https://gist.github.com/strager/e86e355cf8b9d60a0ff9b785506a34f9

from argparse import ArgumentParser, Namespace as arg_namespace
from i3ipc import connection as i3_con, events as i3_events
from my_helper import gen_path_file, process_exec
from pathlib import Path
from typing import Callable, Optional

parser: ArgumentParser = ArgumentParser()
parser.add_argument('--application', action='store_true', help='Displays ONLY the foreground windows Application name.')
parser.add_argument('--title', action='store_true', help='Displays ONLY the foreground windows Title.')
parser.add_argument('--len_title', '--lt', nargs=1, type=int, help='Max length of the title, you want to display.')
parser.add_argument('--application_colors', '--ac', nargs=2, type=str, help='Override the background & foreground colors, of the displayed text.  Colors must be specified in hex format and in the order: bg fg')
parser.add_argument('--title_colors', '--tc', nargs=2, type=str, help='Override the background & foreground colors, of the displayed text.  Colors must be specified in hex format and in the order: bg fg')
args: arg_namespace = parser.parse_args()

def read_configuration() -> None:
    """ Default location: <script execution directory>/window_info.conf

        Format:
            <comment>   - First character needs to be a pound sign.
            <section>   - Either [ignore] or [exclude]

                          [ignore]  - Classes you want window_info to completely ignore 100%.
                          [exclude] - Classes you want window_info to ignore, when displaying
                                    the title.  i.e. titles with valid "-" in them.

            <classname> - Listed under one of the above mentioned sections.
                          Don't wrap it in quotes or anything.

            Example:
                          [ignore]
                          spectacle
                          krunner

                          [exclude]
                          Code

        Note: Semi-user and junk proof.
    """
    config_file: Path = gen_path_file('window_info.conf', __file__, path_obj=True)

    if (config_file.is_file()):
        with config_file.open('r') as cfgFile:
            append_it: list[str] = []

            orig_id: int = id(append_it)

            for b in (l.strip() for l in cfgFile.read().splitlines()):
                if b and not b[0] == '#':
                    if (b[0] == '['):
                        b = b.lower()
                        if  b in ('[ignore]', '[exclude]'):
                            append_it = (ignore_classes if b[1] == 'i'
                                                        else exclude_titles)
                            continue
                        else:
                            append_it = []

                    # id() is essentially as fast as using IS.
                    if not orig_id == id(append_it): # Are we "pointing" to something?
                        append_it.append(b)

def get_window_info() -> str:
    """ Strip the classname from window titles.  SEEMS LIKE the window title
        is in the format f'{window_title} - {classname}'", at least in my case.
        I'm running i3 on Ubuntu.

        Also, this script is NOT 100% perfect and a human could definitely break
        this logic. if you find an app which breaks it, let me know.
    """
    def strip_class_from_title(title: str) -> str:
        if not title:
            return ''

        if focused_window.window_class:
            dashes: str = '-–—' # dash ord : 45, en dash ord : 8211, em dash ord : 8212
            str_dashes: str = f' {dashes}'

            strip_lower: Callable[[str], str] = lambda s: ''.join(
                                        (c for c in s if not c in str_dashes)
                                        ).lower()

            stripped_class: str = strip_lower(focused_window.window_class)
            exclude_me: bool = focused_window.window_class in exclude_titles
            lt: int = len(title) - 1

            # Most cases this should return during the first iteration.
            for i, c in enumerate(title[::-1]):
                if c in dashes and (exclude_me or \
                    strip_lower(title[lt - i:]) == stripped_class):
                    return title[:lt - i]

        return title

    def colorize_text(format_str: str, format_colors: list[str], bold: bool = False) -> str:
        """ If you want bold to work, you need a font-2 def in you polybar config.

            Recently added a special case for VSCode, if a file needs saved, it'll
            display the window title in red.  I MAY get rid of this.
            In VSCode, Red really means there's a linting error.
        """
        special_fg_color: str = '#FF0000' if format_str[0] == '●' else format_colors[1]

        return '' if len(format_str) < 3 else f"%{{B{format_colors[0]}}}" \
                                              f"%{{F{special_fg_color}}}" \
                                              f"{'%{T3}' if bold else ''}" \
                                              f"{format_str}{'%{T-}' if bold else ''}" \
                                              f"%{{B- F-}}"

    focused_window = i3.get_tree().find_focused()

    if focused_window.window_class in ignore_classes:
        return prev_info

    application_text = title_text = 'Finder'

    is_container: bool = focused_window.type == 'con'

    if not args.title:
        # Not a container, assume it's the desktop which has focus.
        if is_container:
            application_text = '' if focused_window.window_class is None \
                                  else ''.join([t.title() \
                                    for t in focused_window.window_class.split()])
        else:
            title_text = ''

        application_text = f" {' ' if not application_text == '' else ''}{application_text.strip()}  "

        if args.application_colors:
            application_text = colorize_text(application_text, args.application_colors, True)

        globals()['prev_info'] = application_text

    if not args.application:
        if is_container:
            title_text = strip_class_from_title(focused_window.window_title)

            # Restrict the number of characters which are displayed.
            if args.len_title:
                l = args.len_title[0]
                if len(title_text) > l:
                    title_text = f'{title_text[0:l]}...'

        title_text = f"{'  ' if args.title else ''}{title_text}  "

        if args.title_colors:
            title_text = colorize_text(title_text, args.title_colors)

        globals()['prev_info'] = title_text

    if args.application or args.title:
        return prev_info

    return f'{application_text}{title_text}'

def on_window_title(c: Optional[i3_con.Connection] = None,
                    e: Optional[i3_events.WindowEvent] = None) -> None:
    print(get_window_info())

(ignore_classes, exclude_titles) = ([], [])

read_configuration()

i3: i3_con = i3_con.Connection()

i3.on('window::focus', on_window_title)
i3.on('window::title', on_window_title)
i3.on('window::close', on_window_title)
i3.on('workspace', on_window_title)

prev_info: str = ''

on_window_title()

i3.main()

process_exec(f"notify-send 'window_info.py:' 'Script has terminated ...'")
