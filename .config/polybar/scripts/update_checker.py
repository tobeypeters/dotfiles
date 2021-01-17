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

#   Count the number of app upgrades are available.

from subprocess import Popen, PIPE

def colorizeText(formatStr: str, formatColors: []) -> str:
    return '' if len(formatStr) < 3 else \
        f'%{{B{formatColors[0]}}}%{{F{formatColors[1]}}}{formatStr}%{{B- F-}}'
        
def pexec(command: str) -> str:
    p = Popen(command, shell=True, stdout=PIPE, stderr=PIPE)
    output, errors = p.communicate()
    return output.decode(encoding="utf-8", errors="ignore")

print(f"{'' if int(pexec('apt list --upgradable | wc -l')) == 1 else ''}")