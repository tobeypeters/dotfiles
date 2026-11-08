CC        = gcc
CFLAGS    = -Wall -O0 -g
SDLCFLAGS := $(shell pkg-config --cflags sdl2)
SDLLIBS   := $(shell pkg-config --libs sdl2)
XMPCFLAGS := $(shell pkg-config --cflags libxmp)
XMPLIBS   := $(shell pkg-config --libs libxmp)
GTKCFLAGS := $(shell pkg-config --cflags gtk+-3.0)
GTKLIBS   := $(shell pkg-config --libs gtk+-3.0)

OBJS = main.o gui.o native_dialog.o

modplayer: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(SDLLIBS) $(XMPLIBS) $(GTKLIBS)

main.o: main.c gui.h native_dialog.h
	$(CC) $(CFLAGS) $(SDLCFLAGS) $(XMPCFLAGS) -c -o $@ main.c

gui.o: gui.c gui.h
	$(CC) $(CFLAGS) $(SDLCFLAGS) $(XMPCFLAGS) -c -o $@ gui.c

native_dialog.o: native_dialog.c native_dialog.h
	$(CC) $(CFLAGS) $(GTKCFLAGS) -c -o $@ native_dialog.c

clean:
	rm -f $(OBJS) modplayer

.PHONY: clean
