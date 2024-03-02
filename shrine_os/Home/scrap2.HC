U8 gato[5];
MemSet(gato,'\0',sizeof(gato));

//"%s\n",gato;


U0 test(U8 *buffer)
{
  U64 i=0;
  "\n";
  while(*buffer)
  {
    if (*buffer==32) break;
    "%c",buffer[0];

    gato[i]=buffer[0];

    buffer++;i++;
  }
  "\n%d %s\n",i,gato;
}

test("one two three four");

"%s\n",gato;
