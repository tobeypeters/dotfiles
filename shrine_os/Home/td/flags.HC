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

/*flags.HC
  Description:
      Defines and handles flags.
*/
#define FLG_A 'a'
#define FLG_B 'b'
#define FLG_C 'c'
#define FLG_D 'd'
#define FLG_E 'e'
#define FLG_F 'f'
#define FLG_G 'g'
#define FLG_H 'h'
#define FLG_I 'i'
#define FLG_J 'j'
#define FLG_K 'k'
#define FLG_L 'l'
#define FLG_M 'm'
#define FLG_N 'n'
#define FLG_O 'o'
#define FLG_P 'p'
#define FLG_Q 'q'
#define FLG_R 'r'
#define FLG_S 's'
#define FLG_T 't'
#define FLG_U 'u'
#define FLG_V 'v'
#define FLG_W 'w'
#define FLG_X 'x'
#define FLG_Y 'y'
#define FLG_Z 'z'

Bool flag_val(U8 *flags,U64 chr)
{//Is chr present, in the the flags we got?
  flags=StrLower(flags);
  while (*flags) {
    if (*flags==chr) return TRUE;
    flags++;
  }
  return FALSE;  
}
U64 flag_cnt(U8 *flags)
{//Get the number of provided flags.
  return StrLen(flags)-(*flags=='-');
}
Bool flag_err(U8 *flags=NULL, U8 *flag_want,Bool print_err=TRUE,U8 *help_file=NULL,U8 *cmd=NULL)
{//Validate the provied flag. If it's not potentially print an error message.
  if (flag_val(flags,flag_want)) return FALSE;
  if (print_err) err_print(ERR_FLGI,,help_file,cmd);
  return TRUE;
}

/*Below is the old version, which used a more TempleOS style flag system.
//Terry used to allow, "-A-B+C-D+E", to allow things to be turn ON&OFF.
//I don't need that.

DefineLstLoad("ST_FLAGS","a\0b\0c\0d\0e\0f\0g\0h\0i\0j\0k\0l\0m\0n\0o\0p\0q\0r\0s\0t\0u\0v\0w\0x\0y\0z\0");

#define FLG_A 0x0000001 //a
#define FLG_B 0x0000002 //b
#define FLG_C 0x0000004 //c
#define FLG_D 0x0000008 //d
#define FLG_E 0x0000010 //e
#define FLG_F 0x0000020 //f
#define FLG_G 0x0000040 //g
#define FLG_H 0x0000080 //h
#define FLG_I 0x0000100 //i
#define FLG_J 0x0000200 //j
#define FLG_K 0x0000400 //k
#define FLG_L 0x0000800 //l
#define FLG_M 0x0001000 //m
#define FLG_N 0x0002000 //n
#define FLG_O 0x0004000 //o
#define FLG_P 0x0008000 //p
#define FLG_Q 0x0010000 //q
#define FLG_R 0x0020000 //r
#define FLG_S 0x0040000 //s
#define FLG_T 0x0080000 //t
#define FLG_U 0x0100000 //u
#define FLG_V 0x0200000 //v
#define FLG_W 0x0400000 //w
#define FLG_X 0x0800000 //x
#define FLG_Y 0x1000000 //y
#define FLG_Z 0x2000000 //z

U64 flags_val(U8 *flag)
{//NOTE: Number of flags is restricted to 7.
 //      Flags are valid, only if it's a letter.
  U64 res=0,
        i=0;

  if (!(*flag=='-')) return res;

  flag=MStrUtil(flag,SUF_TO_UPPER);

  flag++;
  while (*flag&&i<7)
  {
    res.u8[i]=InRangeI64(*flag,'A','Z');

    i++;flag++;
  }
  res.u8[7]=i; //flag count

  return res;
}
/*U64 cnt=flags_val("-ABCD9FG");
"\n";
U8 *buffer=CAlloc(sizeof(U8)*8);
DebugPRN(StrPrint(buffer,"%d",cnt.u8[7]));
Free(buffer);
"\n";
*/
U0 flag_scan(U8 *dst,U8 *lst,U8 *src)
{//Stripped down version of ScanFlags. '-'flags only
 //'-' is '+' and multiple flags are combined.
 //templeOS: +f+a  myStyle: -fa
  "%s\n",src;

  I64 i=0;

  U8 *buf=CAlloc(sizeof(U8)*2);

  src++;
  while (*src)
  {
    buf[0]=src[0];

    i=LstMatch(buf,lst);
    if (i>=0) LBts(dst,i);
    
    src++;
  }
  Free(buf);

/*
  I64 i;
  U8 *buf,*ptr;
  if (src) {
    buf=MAlloc(StrLen(src)+1);
    while (*src) {
      while (*src && *src!='-')
	src++;
      if (*src=='-') {
	src++;
	if (*src) {
	  ptr=buf;
	  while (*src && *src!='-' && *src!=CH_SPACE &&
                 *src!=CH_SHIFT_SPACE)
	    *ptr++=*src++;
	  *ptr=0;
	  i=LstMatch(buf,lst);
	  if (i>=0)
	    LBts(dst,i);
	}
      }
    }
    Free(buf);
  }
*/
}
Bool flag_got(U8 *flags=NULL, I64 flag_want)
{//Search for a certain flag.
  I64 f=0;

  flag_scan(&f,Define("ST_FLAGS"),flags);

  return ToBool((f&flag_want));
}
Bool flag_err(U8 *flags=NULL, I64 flag_want,Bool print_err=TRUE,U8 *help_file=NULL,U8 *cmd=NULL)
{
  Bool res=FALSE;

  if ((res=!flag_got(flags,flag_want)))
    if (print_err) err_print(ERR_FLGI,,help_file,cmd);

  return res;
}
/*"--------------------------------\n";
if (flag_err("-afb",FLG_A)) "yes a\n";
if (flag_err("-afb",FLG_Q,FALSE)) "yes q\n";
if (flag_err("-afb",FLG_B)) "yes b\n";
if (flag_err("-afb",FLG_T,FALSE)) "yes t\n";
if (flag_err("-afb",FLG_F)) "yes g\n";
"--------------------------------\n";*/
*/