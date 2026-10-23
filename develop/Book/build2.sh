#!/usr/bin/env bash
 
: <<'LICENSE'
  The MIT License (MIT)
  Copyright (c) Tobey Peters
  See full license at: https://github.com/tobeypeters
LICENSE

: <<'DESCRIPTION'
  Generates a epub file from book.txt.
DESCRIPTION

rm book2.epub
pandoc book2.txt --epub-cover-image=bookraynewolf.png --metadata title="Book 2" --metadata-file=book.yaml -t epub3 -o book2.epub
