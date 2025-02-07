#! /bin/sh

: <<'LICENSE'
  The MIT License (MIT)
  Copyright (c) Tobey Peters
  See full license at: https://github.com/tobeypeters
LICENSE

: <<'DESCRIPTION'
  Gets the date & time and outputs it.
DESCRIPTION

WIDTH=${WIDTH:-200}
HEIGHT=${HEIGHT:-200}
DATEFMT=${DATEFMT:-"+%a %d %b %H:%M"}
SHORTFMT=${SHORTFMT:-"+%H:%M"}

OPTIND=1
while getopts ":f:W:H:" opt; do
    case $opt in
        f) DATEFMT="$OPTARG" ;;
        W) WIDTH="$OPTARG" ;;
        H) HEIGHT="$OPTARG" ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

case "$BLOCK_BUTTON" in
  1|2|3)


	# the position of the upper left corner of the popup
	posX=$((BLOCK_X - WIDTH))
	posY=$((BLOCK_Y))

	i3-msg -q "exec yad --calendar \
        --width=$WIDTH --height=$HEIGHT \
	   --undecorated --fixed \
            --show-weeks \
	   --close-on-unfocus --no-buttons \
	   --posx=$posX --posy=$posY \
	   > /dev/null"
esac
echo "$LABEL$(date "$DATEFMT")"
echo "$LABEL$(date "$SHORTFMT")"