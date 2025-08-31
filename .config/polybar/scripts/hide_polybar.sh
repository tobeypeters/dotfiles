#!/usr/bin/env bash

: <<'LICENSE'
  The MIT License (MIT)
  Copyright (c) Tobey Peters
  See full license at: https://github.com/tobeypeters
LICENSE

: <<'DESCRIPTION'
  Waits for an instance of polybar message queue to be created.
  Whenever it finds it, this will hide the current instance of polybar.
  This is just my dumb and simple way to do it.
DESCRIPTION

pid=$(pidof polybar)
polybar-msg -p $pid cmd hide
