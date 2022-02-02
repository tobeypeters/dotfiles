U0 More(U8 *filename)
{//Output txt or graphic file to the command line,
 //one screen at a time.
  I64 size = 0;

  U64 max_lines = Fs->win_bottom -
                  Fs->win_top,
              i = 0,
             cl = 0;

  U8 *buffer;

  buffer = FileRead(filename,&size);

  DocClear; DocTop;

  for (;i < size; i++) {
    "%c",buffer[i];

    if (buffer[i] == '\n') cl++;

    if (cl == max_lines) {
      KeyAndCont;
      cl = 0;
    }
  }

  "\n";

  MemSet(buffer, '\0', sizeof(U8)*size);
}

More("./chain.HC");
