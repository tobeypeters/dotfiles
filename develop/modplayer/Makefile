CC        = gcc
CFLAGS    = -Wall -O2
SDLCFLAGS := $(shell pkg-config --cflags sdl2)
SDLLIBS   := $(shell pkg-config --libs sdl2)
XMPCFLAGS := $(shell pkg-config --cflags libxmp)
XMPLIBS   := $(shell pkg-config --libs libxmp)
GTKCFLAGS := $(shell pkg-config --cflags gtk+-3.0)
GTKLIBS   := $(shell pkg-config --libs gtk+-3.0)
AVCFLAGS  := $(shell pkg-config --cflags libavformat libavcodec libavutil libswresample)
AVLIBS    := $(shell pkg-config --libs   libavformat libavcodec libavutil libswresample)

OBJS = main.o gui.o native_dialog.o ffmpeg_player.o

modplayer: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(SDLLIBS) $(XMPLIBS) $(GTKLIBS) $(AVLIBS) -lpthread

main.o: main.c gui.h native_dialog.h ffmpeg_player.h
	$(CC) $(CFLAGS) $(SDLCFLAGS) $(XMPCFLAGS) $(AVCFLAGS) -c -o $@ main.c

gui.o: gui.c gui.h
	$(CC) $(CFLAGS) $(SDLCFLAGS) $(XMPCFLAGS) -c -o $@ gui.c

native_dialog.o: native_dialog.c native_dialog.h
	$(CC) $(CFLAGS) $(GTKCFLAGS) -c -o $@ native_dialog.c

ffmpeg_player.o: ffmpeg_player.c ffmpeg_player.h
	$(CC) $(CFLAGS) $(AVCFLAGS) -c -o $@ ffmpeg_player.c

clean:
	rm -f $(OBJS) modplayer

.PHONY: clean
