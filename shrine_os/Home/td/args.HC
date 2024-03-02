#define ARG_CNT 64
#define ARG_LEN 256

class CArgs
{
  U0 (*parse)(CArgs *in,U8 *cmd,U8 delim=32,U64 ins_idx=0);
  U0 (*init)(CArgs *in);
  U0 (*next)(CArgs *in);
  U0 (*prev)(CArgs *in);

  U8 data[ARG_CNT][ARG_LEN];

  I64 count,cidx;
};

U0 parse(CArgs *in,U8 *cmd,U8 delim=32,U64 ins_idx=0)
{//Parse command buffer
  if (!cmd[0]) return;

  U64 p=0;

  in->count=ins_idx;

  while (cmd[0])
  {
    if (cmd[0]==delim)
    {
//      ins_idx++; cmd++;
      ins_idx++;
      parse(in,cmd,,ins_idx);

      break;
    }

    in->data[ins_idx][p]=cmd[0]; p++;

    cmd++;
  }
}
U0 init(CArgs *in)
{//Initizlizer and reset CArgs function
  MemSet(in->data, '\0', sizeof(U8)*ARG_CNT*ARG_LEN);
  in->count=in->cidx=0;
}

U0 next(CArgs *in) { in->cidx=Min(in->count,++in->cidx); }
U0 prev(CArgs *in) { in->cidx=Max(0,--in->cidx); }

CArgs *a=MAlloc(sizeof(CArgs));
  a->init=&init;
  a->parse=&parse;
  a->next=&next;
  a->prev=&prev; 

  a->init(a);
    "\n";
    a->parse(a,"one two three four five\n");
    "a->count: %d <-Add 1 to get the real count a->data[2]: %s\n\n",a->count,a->data[2];

    "%s\n",a->data[a->cidx];
    a->prev(a);"%s\n",a->data[a->cidx];
    a->prev(a);"%s\n",a->data[a->cidx];
    a->next(a);"%s\n",a->data[a->cidx];
    a->next(a);"%s\n",a->data[a->cidx];
    a->next(a);"%s\n",a->data[a->cidx];
    a->next(a);"%s\n",a->data[a->cidx];
    a->next(a);"%s\n",a->data[a->cidx];
    a->next(a);"%s\n",a->data[a->cidx];
    a->next(a);"%s\n",a->data[a->cidx];

  a->init(a);
Free(a);
"\n";