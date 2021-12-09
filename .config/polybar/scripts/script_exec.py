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

""" script_execute.py
    Description:
        Builds a selectable list of scripts, which you can execute.

    Arguments:
        --directory --d Directory of scripts, to generate list from.

    Usage:
        script_exec.py
        script_exec.py --directory "./myscripts"

    Default:
        './scripts
"""

from argparse import ArgumentParser, Namespace as arg_namespace
from i3ipc import connection as i3_con, events as i3_events
from my_helper import gen_path_file, process_exec
from pathlib import Path
from sys import exit, stderr
from typing import Callable, Optional

parser: ArgumentParser = ArgumentParser()
parser.add_argument('--directory', '--d',
                    default=Path.joinpath(Path(__file__).parent, 'scripts'),
                    help='Directory of scripts (default: <current directory> + "/scripts"\n"%(default)s"')
args: arg_namespace = parser.parse_args()

path = Path(args.directory)

if not path.is_dir():
    print(f'\nDirectory: {path} does not exist ... ', file=stderr)
    exit(1)

script_items: str = ''
script_cmds: str = ''
for file in path.glob('*'):
    script_items += f"'{Path(file).stem}' "
    script_cmds += f"'i3-sensible-terminal -e {file}' "

script_items = script_items.rstrip()
script_cmds = script_cmds.rstrip()

c_args: str = f"--items {script_items} --commands {script_cmds}"
command: str = gen_path_file('generic_popup.py', __file__, c_args)

process_exec(command)
