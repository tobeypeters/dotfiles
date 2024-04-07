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

""" wallpaperlock.py
	Description:
		Part of the wallpaper & color scheme locking system.
        Generates the lock file or deletes it, if it's there.
"""
import os

# Specify the name of the environment variable you want to retrieve
filename = os.path.expanduser("~/Pictures/Wallpapers/wallpaper.lock")
wall_name = "WALLPAPER"
wallpaper  = "not specified"

# Check if the variable exists in the environment
if os.path.exists(filename):
    os.chmod(filename, 0o644)
    os.remove(filename)
else:
    if wall_name in os.environ:
        wallpaper = os.environ[wall_name]

    with open(filename, 'w') as file:
        file.write(wallpaper)
        os.chmod(filename, 0o400)
