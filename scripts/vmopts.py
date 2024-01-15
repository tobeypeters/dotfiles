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

""" vmopts.py
    Description:
        Allow you to mount, unmount, and sync files to/from qemu & vdi files.
        The sync option is tailored for syncing Home directories, to and from
        TempleOS based distros - TempleOS, ShrineOS, ZealOS, etc ...  Mount and
        unmount should work with any qemu and vdi file ... I believe. Should???

    Arguments:
"""
from argparse import ArgumentParser, Namespace as arg_namespace
from pathlib import Path
import subprocess
import os

# ANSI color escape codes
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    END = '\033[0m'

def is_valid_file(parser, arg):
    """Check if the provided file for ISO argument is valid."""
    arg_path = Path(arg)
    if not arg_path.exists():
        parser.error(f"The file '{arg}' does not exist.")
    return arg_path

def is_folder_mounted(folder_path):
    return os.path.ismount(folder_path)

def update_mode_based_on_extension(args):
    """Description:
           I only handle qcow2 for qemu and vdi for Virtual Box.
           So, If the ISO file provided has a vdi extension, FORCE switch the
           mode to vdi.
    """
    if args.iso.suffix.lower() == '.vdi':
        args.mode = 'vdi'

parser: ArgumentParser = ArgumentParser(
        description=f'{Colors.GREEN}VM ISO Operations Script: Mount, unmount, and sync ISO files for QEMU and VirtualBox.{Colors.END}',
        epilog='Example: vmopts.py -i /path/to/my.iso -m vdi -o unmount'
    )

# Mandatory argument
parser.add_argument('-i', '--iso', help='Path to the ISO file', required=True, type=lambda x: is_valid_file(parser, x))

# Optional arguments with default values
parser.add_argument('-m', '--mode', choices=['qemu', 'vdi'], default='qemu', help='Mode for VM ISO operation qemu or vdi. (default: qemu)')
parser.add_argument('-o', '--operation', choices=['mount', 'unmount', 'sync_local', 'sync_remote'], default='mount', help='VM ISO Operation to mount, unmount, and sync HOME folder to [TempleOS, shrineOS, ZealOS, etc ...]')

args: arg_namespace = parser.parse_args()

# Update mode based on file extension
update_mode_based_on_extension(args)

print(args)

commands = []
if (args.mode == 'qemu'):
    #https://www.howtogeek.com/devops/how-to-mount-a-qemu-virtual-disk-image/
    if (args.operation == 'mount'):
        commands = [
            'sync',
            'mkdir -p ./mnt',
            f'sudo mount -o loop,offset=32256,rw,uid=`id -u`,gid=`id -g` {args.iso} ./mnt'
        ]
    if (args.operation == 'unmount'):
        commands = [
            'sudo umount -l ./mnt'
        ]
else:
    #https://devicetests.com/mount-virtualbox-drive-image-ubuntu
    if (args.operation == 'mount'):
        commands = [
            'sync',
            'mkdir -p ./mnt',
            'sudo rmmod nbd',
            'sudo modprobe nbd max_part=16',
            f'sudo qemu-nbd -c /dev/nbd0 {args.iso}',
            'sudo mount /dev/nbd0p1 ./mnt',
        ]
    if (args.operation == 'unmount'):
        commands = [
            'sudo umount -l ./mnt',
            'sudo qemu-nbd -d /dev/nbd0'
        ]
if (args.operation == 'sync_local' or
    args.operation == 'sync_remote'):
    print('qemu: sync\n')
    print('rsync -avz --delete .'
          f'{"/mnt/Home ./" if args.operation == "sync_local" else "/Home ./mnt"}')

#host     rsync -avz --delete ./mnt/Home ./
#remote   rsync -avz --delete ./Home ./mnt

for command in commands:
    subprocess.run(command, shell=True)
