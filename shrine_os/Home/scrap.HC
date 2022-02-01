U0 More(U8 *filename)
{//Output txt or graphic file to the command line,
 //one screen at a time.
  I64 size = 0;

  U64 i = 0,
      j = 0;

  U8 *buffer;

  buffer = FileRead(filename,&size);

  "size %d\n",size;

  for (;i < size; i++) {
    "%c",buffer[i];
  }

//  "buffer : %s\n",buffer;

//  for (;i < (Fs->win_bottom - Fs->win_top); i++) {
//    while (buffer[j] != '\0' && buffer[j] != '\n') {
//      '%c',buffer[j];
//    }
//    j++; 
//  }

  MemSet(buffer, '\0', sizeof(U8)*size);

}

More("./chain.HC");