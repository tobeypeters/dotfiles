U8 *gato[1][3];
MemSet(gato,'\0',sizeof(gato));

gato[0][0]=0;
gato[0][1]="happy";
gato[0][2]=1;

"%d %s %d\n",gato[0][0],gato[0][1],gato[0][2];

/*U8 gato[5];
MemSet(gato,'\0',sizeof(gato));

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
  "\n%d %s\n",i,gato;
}

test("one two three four");

"%s\n",gato;
*/