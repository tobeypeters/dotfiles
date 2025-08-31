#!/usr/bin/env bash
 
: <<'LICENSE'
  The MIT License (MIT)
  Copyright (c) Tobey Peters
  See full license at: https://github.com/tobeypeters
LICENSE

: <<'DESCRIPTION'
  Power Options - logout, reboot, shutdown
DESCRIPTION

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
