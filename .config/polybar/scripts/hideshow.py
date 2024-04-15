#!/usr/bin/env python3

#   The MIT License(MIT)
#
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

#   Made for : https://www.reddit.com/user/LOLTROLDUDES/
#   Description:
#   Hide the polybar if any apps are open on the current desktop.
#   Else, hide it.

from i3ipc import Connection
from subprocess import call

i3 = Connection()

def sendBarMessage(inTail):
    call([ 'polybar-msg', 'cmd', inTail ])

def on_ShowHide(self, e):
    tail = 'hide' if len(i3.get_tree().find_focused().workspace().\
            descendants()) > 0 else 'show'

    sendBarMessage(tail)

i3.on('window', on_ShowHide)
i3.on('workspace', on_ShowHide)

on_ShowHide('', '')

i3.main()

#sendBarMessage('show')