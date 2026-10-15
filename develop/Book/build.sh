#!/usr/bin/env bash
 
: <<'LICENSE'
  The MIT License (MIT)
  Copyright (c) Tobey Peters
  See full license at: https://github.com/tobeypeters
LICENSE

: <<'DESCRIPTION'
  Generates a epub file from book.txt.
DESCRIPTION

rm book.epub
pandoc book.txt --epub-cover-image=bookraynewolf.png --metadata title="Book" --metadata-file=book.yaml -t epub3 -o book.epub
