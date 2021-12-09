#!/usr/bin/env python3

from re import match
from subprocess import Popen, PIPE
from sys import exit

def process_exec(p_cmd: str) -> str:
	p = Popen(p_cmd, shell=True, stdout=PIPE, stderr=PIPE)
	_, output = p.communicate()
	return output.decode(encoding="utf-8", errors="ignore")

required_packages = ['coreutils', 'sed', 'gawk', 'curl']

dep_check = process_exec(
    f"apt list {' '.join(required_packages)} | grep 'installed'"
)

if not dep_check == '':
    missing_packages = [ p for p in required_packages
                         if (dep_check.find(f'{p}/') == -1)
    ]

    if len(missing_packages) > 0:
        print("\n----------\n")
        print("the following dependencies are missing:")

        for d in missing_packages:
            print("    " + d)

        if match(r'^y(es)?$', input("\nwould you like to install\
             them now? [yes/no]> ").lower()):
            process_exec(
                f"sudo apt install -y {' '.join(missing_packages)}")
        else:
            exit("\ninstall missing dependencies!")
    else:
        print(f"\n{required_packages} are all currently installed.")