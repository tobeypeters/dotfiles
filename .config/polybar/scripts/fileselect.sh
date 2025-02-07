#!/bin/bash

: <<'LICENSE'
  The MIT License (MIT)
  Copyright (c) Tobey Peters
  See full license at: https://github.com/tobeypeters
LICENSE

: <<'DESCRIPTION'
  Allows you to select a file "movie" and open it.
DESCRIPTION

# Set the target directory
DIR="/media/tibegato/StorageDaemon/Theater"

# Run dmenu with the same colors as dmenu_run
SELECTED_FILE=$(ls "$DIR" | dmenu -nb $2 -nf $1 -sb $1 -sf $2 -l -i -p 'Movie:')

# Open the file if one is selected
[ -n "$SELECTED_FILE" ] && xdg-open "$DIR/$SELECTED_FILE"
