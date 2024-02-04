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

""" gitclone_folder.py
    Description:
         Allows you to clone a single folder, from a git repository.

    Arguments:
        repository_url  URL of the Git repository.
        branch          Branch name of the repository.
                        Use "help" for the branch name, to get a list
                        of available branches.
        folder_path     Path to the specific folder to clone.

        ./gitclone_folder.py https://github.com/tinkeros/Alec_stuff_backup.git help cosmo_engine
    Resources:
        Get a list of branches available command:
        git ls-remote --heads https://github.com/tinkeros/Alec_stuff_backup.git
"""
from argparse import ArgumentParser, Namespace as arg_namespace
from sys import exit
from typing import List
import subprocess
import shutil
import os

# ANSI color escape codes
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    END = '\033[0m'

class MESSAGES:
    EPILOG= f'{Colors.GREEN}Example:{Colors.END}'
    HELP = f'{Colors.GREEN}Clone a specific folder from a Git repository.{Colors.END}'
    BRANCHES = f'{Colors.RED}\nAvailable branches:{Colors.END}'
    SUCCESS = f'{Colors.GREEN}Successfully{Colors.END}'
    REPO = f'{Colors.GREEN}Repository: {Colors.END}'

def process_exec(command: List[str], verbose: bool = False) -> None:
    try:
        # result = subprocess.run(command, capture_output=True, text=True)
        result = subprocess.run(command, stdout=subprocess.PIPE, text=True)
        if verbose:
            print(f'\nCommand executed: {" ".join(command)}')
            print(f'          Stdout: {result.stdout}')
        return result
    except subprocess.CalledProcessError as e:
        print(f'Error: {e}')
        exit(1)

    return None

def clone_folder(args: arg_namespace) -> None:
    command: List[str] = ['']

    # Create a temporary directory
    temp_dir: str = 'temp_clone'

    command = [
        'git', 'clone',
        # '--depth', '1',
        '--branch', args.branch,
        args.repository_url,
        temp_dir
    ]
    # Clone the repository with --depth 1
    # subprocess.run(command)
    process_exec(command, args.verbose)

    command = [
        'cp', '-r',
        f'{temp_dir}/{args.folder_path}/', '.'
    ]
    # Copy the contents of the specified folder
    # subprocess.run(command)
    process_exec(command, args.verbose)

    # Clean up the temporary directory
    shutil.rmtree(temp_dir)

def get_branches(repo_url: str, verbose: bool = False) -> None:
    # Construct the Git command to get remote branches
    command: List[str] = [
        'git', 'ls-remote', '--heads', repo_url
    ]

    # Run the Git command to get branches
    # result = subprocess.run(command, stdout=subprocess.PIPE, text=True)
    result = process_exec(command, verbose)

    # Extract branch names
    branches: List[str] = [line.split('refs/heads/')[1].strip() for line in result.stdout.splitlines()]

    if verbose:
        print(f'{Colors.GREEN}Verbose mode:{Colors.END}\nShowing available branches for repository: {repo_url}')

    print(MESSAGES.BRANCHES)
    for branch in branches:
        print(branch)

    return

def main() -> None:
    # Create an argument parser
    parser: ArgumentParser = ArgumentParser(
        description=(MESSAGES.HELP),
        epilog=f'{MESSAGES.EPILOG} ./gitclone_folder.py https://github.com/example/repo.git help desired_folder')

    # Add required arguments
    parser.add_argument('repository_url', help='URL of the Git repository')
    parser.add_argument('branch', help='Branch name of the repository. Use "help" to get a list of available branches.')
    parser.add_argument('folder_path', help='Path to the specific folder to clone')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose mode')

    # Parse the command-line arguments
    args: arg_namespace = parser.parse_args()

    # If the user entered "help" for the branch, show available branches
    if args.branch.lower() == 'help':
        get_branches(args.repository_url, args.verbose)
        return

    # Call the function to clone the folder
    print(f'\n{MESSAGES.REPO}{args.repository_url}')
    clone_folder(args)
    print(f'\n{MESSAGES.SUCCESS} cloned folder {Colors.GREEN}{args.folder_path}{Colors.END} from {args.repository_url} on branch {Colors.RED}{args.branch}{Colors.END}')

    exit(0)

if __name__ == '__main__':
    main()