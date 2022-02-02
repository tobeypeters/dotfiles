U0 More(U8 *filename)
{//Output txt or graphic file to the command line,
 //one screen at a time.
  #define MAX_CHARS Fs->win_right - Fs->win_left - 4
  #define MAX_LINES Fs->win_bottom - Fs->win_top - 4

  "%d %d\n",MAX_CHARS,MAX_LINES;

  KeyAndCont;

  I64 size = 0;

  U64 i = 0,
      c = 0,
     cl = 0;

  U8 *buffer;

  buffer = FileRead(filename,&size);

  for (;i < size; i++) {
    "%c",buffer[i]; c++;

    if (buffer[i] == '\n') c = MAX_CHARS;
    if (c == MAX_CHARS) cl++;

    if (cl == MAX_LINES) {
      KeyAndCont;
      cl = 0;
    }
  }

  MemSet(buffer, '\0', sizeof(U8)*size);

}

More("./chain.HC");

/////////////////////////////////////////////////////////////////////////////a
