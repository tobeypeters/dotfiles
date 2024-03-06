/*
  The MIT License(MIT)
  Copyright(c), Tobey Peters, https://github.com/tobeypeters
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
  and associated documentation files (the "Software"), to deal in the Software without restriction,
  including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
  subject to the following conditions:
  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*args.HC
  Description:
      Parse a string, into individual arguments.
*/

#define ARG_CNT 64
#define ARG_LEN 256

class CArgs
{
  I64 count,
      cidx;

  U8 data[ARG_CNT][ARG_LEN];

  U0 (*parse)(CArgs *in,U8 *cmd,U8 delim=32,U64 ins_idx=0);
  U0 (*init)(CArgs *in);
  U0 (*next)(CArgs *in);
  U0 (*prev)(CArgs *in);
};

U0 parse(CArgs *in,U8 *cmd,U8 delim=32,U64 ins_idx=0)
{//Parse command buffer
  if (!cmd[0]) return;

  U64 p=0;

  in->count=ins_idx+1;

  while(*cmd)
  {
    if(cmd[0]==delim){
      ins_idx++; cmd++;
      parse(in,cmd,,ins_idx);
      break;
    }
    in->data[ins_idx][p]=cmd[0];
    p++;cmd++;
  }
}
U0 init(CArgs *in)
{//Initizlizer and reset CArgs function
  MemSet(in->data, '\0', sizeof(U8)*ARG_CNT*ARG_LEN);
  in->count=in->cidx=0;
}

U0 next(CArgs *in) { in->cidx=Min(in->count-1,++in->cidx); }
U0 prev(CArgs *in) { in->cidx=Max(0,--in->cidx); }

CArgs *a=CAlloc(sizeof(CArgs));
  a->init=&init;
  a->parse=&parse;
  a->next=&next;
  a->prev=&prev; 

/*
//  a->init(a); //Clear data before each proceeding parse() call
    a->parse(a,"one two three four five");

    "\na->count: %d\n\n$$GREEN$$start:$$FG$$\n",a->count;
    a->prev(a);"%6s\n",a->data[a->cidx];
    a->prev(a);"%6s\n",a->data[a->cidx];
    a->next(a);"%6s\n",a->data[a->cidx];
    a->next(a);"%6s\n",a->data[a->cidx];
    a->next(a);"%6s\n",a->data[a->cidx];
    a->next(a);"%6s\n",a->data[a->cidx];

    "$$LTRED$$\nSet a->idx to 1,\nback to \"a->data[2]\"$$FG$$\n\n";
    a->cidx=1;
    a->next(a);"%6s\n",a->data[a->cidx];
    a->next(a);"%6s\n",a->data[a->cidx];
    a->next(a);"%6s\n",a->data[a->cidx];
    "$$GREEN$$:end$$FG$$\n\n";
  a->init(a);
Free(a);
*/