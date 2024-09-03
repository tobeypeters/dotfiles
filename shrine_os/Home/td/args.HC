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

  U8 args[ARG_CNT][ARG_LEN];
  U8 *flags;

  Bool (*parse)(CArgs *in,U8 *cmd,U64 ins_idx=0,Bool init=TRUE);
  U0 (*init)(CArgs *in);
  U8 (*get_current)(CArgs *in);
  U0 (*next)(CArgs *in);
  U0 (*prev)(CArgs *in);
};

Bool parse(CArgs *in,U8 *cmd,U64 ins_idx=0,Bool init=TRUE)
{//Parse command buffer.  This version uses
 //space as the delimeter.
  Bool res=FALSE;

  if (!StrLen(cmd)) return res;

  StrUtil(cmd,SUF_REM_LEADING);

  U64 qf=0,
       p=0;

  in->count=ins_idx+1;

  while(*cmd)
  {
    if(*cmd==32&&!qf){
      ins_idx++; cmd++;
      parse(in,cmd,ins_idx,FALSE);
      break;
    }

    in->args[ins_idx][p]=*cmd;

    qf+=*cmd==34;
    if (!(qf%2)) qf=0;
  
    p++;cmd++;
  }

  //Sorting time
  if (init)
  {
    Bool f=FALSE;

    p=0;
    while (*in->args[p])
    {
      if (in->args[p][0]=='-')
      {
        in->flags=StrNew(in->args[p]);
        f=TRUE;goto done;
      }

      if (f) StrCpy(in->args[p-1],in->args[p]);

      done:
        p++;
    }
    if (f) MemSet(in->args[p-1],'\0',sizeof(U8)*ARG_LEN);
  }

  return in->count>0;
}
U0 init(CArgs *in)
{//Re-init in
  MemSet(in->flags,'\0',sizeof(U8)*StrLen(in->flags));
  MemSet(in->args,'\0',sizeof(U8)*ARG_CNT*ARG_LEN);

  in->count=in->cidx=0;
}
U8* get_current(CArgs *in)
{
  if (in->count<1) return NULL;

//Just return a pointer to it. Should be no peoblems.
//  return StrNew(in->args[in->cidx]);
  return in->args[in->cidx]; 
}

U0 next(CArgs *in) { in->cidx=Min(in->count-1,++in->cidx); }
U0 prev(CArgs *in) { in->cidx=Max(0,--in->cidx); }

CArgs *a=CAlloc(sizeof(CArgs));
  a->init=&init;
  a->parse=&parse;
  a->get_current=&get_current;
  a->next=&next;
  a->prev=&prev;

//  a->init(a); //Clear args before each proceeding parse() call
/*    a->parse(a,"one -TWO three four five");
    a->init(a);
    a->parse(a,"one TWO three four five");
    a->init(a);
    a->parse(a,"-one two three four five");
    a->init(a);
    a->parse(a,"-one");

    "\na->count: %d\n\n$$GREEN$$start:$$FG$$\n",a->count;
    a->prev(a);"%6s\n",a->args[a->cidx];
    a->prev(a);"%6s\n",a->args[a->cidx];
    a->next(a);"%6s\n",a->args[a->cidx];
    a->next(a);"%6s\n",a->args[a->cidx];
    a->next(a);"%6s\n",a->args[a->cidx];
    a->next(a);"%6s\n",a->args[a->cidx];

    "$$LTRED$$\nSet a->idx to 1,\nback to \"a->args[2]\"$$FG$$\n\n";
    a->cidx=1;
    a->next(a);"%6s\n",a->args[a->cidx];
    a->next(a);"%6s\n",a->args[a->cidx];
    a->next(a);"%6s\n",a->args[a->cidx];
    "$$GREEN$$:end$$FG$$\n\n";
  a->init(a);
Free(a);
*/
