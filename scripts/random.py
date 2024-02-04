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

""" random.py
    Description:
        Return a random filename, from a specified folder.

    Arguments:
"""
from argparse import ArgumentParser, Namespace as arg_namespace
import os
import subprocess

# ANSI color escape codes
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    END = '\033[0m'

class MESSAGES:
    HELP = f'{Colors.GREEN}Choose a random file from a folder.{Colors.END}'
    EPILOG= f'{Colors.GREEN}Example:{Colors.END}'

def choose_random_file(fp: str) -> str:
    # Use subprocess to run 'ls' and 'shuf' commands
    try:
        rf: str = subprocess.check_output(['find', fp, '-type', 'f'], encoding='utf-8')
        rf = rf.strip().split('\n')
        rf = subprocess.check_output(['shuf', '-n', '1'], input='\n'.join(rf), encoding='utf-8').strip()
    except subprocess.CalledProcessError:
        return None

    # Construct the full path of the chosen file
    rfp: str = os.path.join(fp, rf)

    # Return the full path of the chosen file
    return rfp

def is_valid_folder(parser: ArgumentParser, arg: str) -> str:
    #Check if the provided folder is valid.
    if not os.path.exists(arg):
        parser.error(f"The folder '{arg}' does not exist.")
        return None
    return arg

# Create an argument parser
parser: ArgumentParser = ArgumentParser(
    description=MESSAGES.HELP,
    epilog=f'{MESSAGES.EPILOG} ./random.py ~/Pictures')

parser.add_argument('folder_path', help='Path to the folder containing files.', type=lambda x: is_valid_folder(parser, x))

# Parse the command-line arguments
args: arg_namespace = parser.parse_args()

print(choose_random_file(args.folder_path))
