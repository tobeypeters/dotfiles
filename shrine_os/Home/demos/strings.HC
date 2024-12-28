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

/*strings.HC
  Description:
      String related functions.
*/
U8 *str_cat(U8 **str,Bool flush=TRUE,...)
{//Build a str, from strings stored in argv.
 //flush clears the buffer first.
  U64 i = 0;

  if (flush) *str = '\0';

  for (;i<argc;i++) {
    CatPrint(str,argv[i]);
  }

  return str;
}


U8 str_upper(U8 *str)
{//Convert a string to uppercase.
  return MStrUtil(str,SUF_TO_UPPER);
}
U8 str_lower(U8 *str)
{//Convert a string to lowercase. 
  return MStrUtil(str,SUF_TO_LOWER);
}
Bool str_cmp(U8 *stra, U8 *strb, Bool ignore_case=FALSE)
{//StrCmp replacement which returns TRUE & FALSE.
 //Saying !StrCmp() for TRUE, erks me ...
  Bool res=FALSE;

  if (ignore_case) {
    res=!StrICmp(stra,strb);
  }
  else { 
    res=!StrCmp(stra,strb);
  }
  return res;
}
Bool str_cmpEX(U8 *cmp_to,Bool ignore_case=FALSE, ...)
{//EXpanded version of str_cmp. It can compare a string,
 //to a list of strings.
 //
 //Example: if (!str_cmpEX(entry->name,,".","..")) { ... }
  if (!cmp_to||argc<1) return FALSE;

  Bool res=FALSE;

  I64 i=0;
  for (;i<argc;i++) {
    if (res=str_cmp(cmp_to,argv[i],ignore_case))
      break;
  }

  return res;
}
U64 str_len(U8 *str) return StrLen(str);
U8 *callocstr(...)
{
  U64 len=0,
        i=0;

  while (i<argc) {
   len+=str_len(argv[i]);
   i++;
  }

  return CAlloc(sizeof(U8)*len+1);
}
U8 *str_rev(U8 *str)
{//Reverse a string.  I thought, TempleOS had one.
 //I can't find it. If there's one buried in the OS,
 //I'll get rid of this one.
 //
 //Example: "%s\n",str_rev("hello world");
  U64 l=StrLen(str)-1,i=0;
  U8 *st=CAlloc(sizeof(U8)*l);

  for (;i<=l;i++) st[i]=str[l-i];

  return st;
}
U8 *str_new(U8 *buf=NULL,CTask *mem_task=NULL,...)
{//String builder, which builds a string from a single 
 //string as normal or muiltiple strings.
 //
 //Example:
 //U8 *buf=str_new("hello world");
 //U8 *buf=str_new(,,"hello"," ","world","!!!");

 //Accepts a $LK,"CTask",A="MN:CTask"$ or $LK,"CHeapCtrl",A="MN:CHeapCtrl"$.NULL allocs off current task's heap.
 //Terrys code
  U8 *res=0;
  I64 size=0;

  if (buf||mem_task) {
    if (buf) {
      size=StrLen(buf)+1;
      res=MAlloc(size,mem_task);
      MemCpy(res,buf,size);
      goto done;
    }
    res=MAlloc(1,mem_task);
    goto done;
  }

  //Non-Terry code
  if (argc) {
    U64 i=0;

    while(i<argc) {
      size+=StrLen(argv[i]);

      i++;
    }

    if (size) size+=1;

    res=CAlloc(sizeof(U8)*size);
    for (i=0;i<argc;i++) {
      CatPrint(res,argv[i]);
    }
  }
  //

done:
  return res;
}
U8 *str_NQ(U8 *str)
{//De-Quotify$CM-LE-RE$$SY,3$tm$SY,0$ a string.
  U8 *p=str;
  while (*str)
  {
    if (*str==34) *str=' ';
    str++;
  }
  str=p;

  return MStrUtil(str,SUF_REM_LEADING|SUF_REM_TRAILING);
}
