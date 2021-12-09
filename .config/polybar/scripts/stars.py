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

"""	stars.py
	Description:
		Displays a starfield in the terminal.

	Notes:
		I recommend running the terminal full-screen.
"""
from os import popen, system
from random import randint
from sys import stdout

RESET: str = "\033[0;37m"
WHITE: str = "\033[1;37m"

def put_text(x, y, text, c = RESET) -> None:
	stdout.write(f"{c}\x1b7\x1b[%d;%df%s\x1b8" % (x, y, text))
	stdout.flush()

rows, columns = popen('stty size', 'r').read().split()

xx, yy = int(rows), int(columns)

system('clear')
#system('setterm -cursor off')

r1, r2  = int((xx * yy) / 20), int((xx * yy) / 100)

# This is probably not the best way to do this
put_args = ['.']
for i in range(r1 + r2):
	if i == r1:
		put_args = ['*', WHITE]
	put_text(randint(1, xx), randint(1, yy), *put_args)

quit_message: str = '___ Press any key to quit ___'

put_text(xx, int(yy / 2) - int(quit_message.__len__() / 2), quit_message, WHITE)

system("""bash -c 'read -s -n 1 -p ""'""")

system('clear')
system('setterm -cursor on')

#print("\33[50;60HB")
