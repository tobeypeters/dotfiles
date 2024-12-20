#!/bin/bash

echo ''<<LICENSE
	The MIT License(MIT)
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
LICENSE

# Power Options - logout, reboot, shutdown

# Check the number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <background color> <foreground color>"
    exit 1
fi

declare -a options=("lock
logout
reboot
shutdown")

choice=$(echo "${options[@]}" | dmenu -nb $2 -nf $1 -sb $1 -sf $2 -l -i -p 'System:')
#'Shutdown' 'systemctl poweroff' -b 'Reboot' 'systemctl reboot' -b 'Logout' 'i3-msg exit'"

case $choice in
	lock)
#		exec i3lock -c '#000000'
		exec i3lock
	;;
	logout)
		exec i3-msg exit
	;;
	reboot)
        exec systemctl reboot
	;;
	shutdown)
        exec systemctl poweroff
	;;
	*)
		exit 1
	;;
esac
