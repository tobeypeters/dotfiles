CC        = gcc
CFLAGS    = -Wall -O2
SDLCFLAGS := $(shell pkg-config --cflags sdl2)
SDLLIBS   := $(shell pkg-config --libs sdl2)
XMPCFLAGS := $(shell pkg-config --cflags libxmp)
XMPLIBS   := $(shell pkg-config --libs libxmp)

modplayer: main.c
	$(CC) $(CFLAGS) $(SDLCFLAGS) $(XMPCFLAGS) -o $@ $< $(SDLLIBS) $(XMPLIBS)

clean:
	rm -f modplayer
