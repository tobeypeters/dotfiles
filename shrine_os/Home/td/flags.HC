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

DefineLstLoad("ST_FLAGS","a\0b\0c\0d\0e\0f\0g\0h\0i\0j\0k\0l\0m\0n\0o\0p\0q\0r\0s\0t\0u\0v\0w\0x\0y\0z\0");

U8 *defined_flags = Define("ST_FLAGS")$WW,1$;

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

#include "C:/Home/td/utils"

U64 flags_val(U8 *flag)
{
  "%s",flag;
  U64 res=0,
        i=0;

  if (!(*flag=='-')) return res;

  flag=MStrUtil(flag,SUF_TO_UPPER);

  flag++;
  while (*flag)
  {
    res.u8[i]=I64_between(*flag,'A','Z');

    i++;flag++;
  }
  res.u8[7]=i; //flag count

  return res;
}

U0 flag_scan(U8 *dst,U8 *lst,U8 *src)
{ //Stripped down version, of ScanFlags. '-'style flags only.
  //Keep TempleOS style flags.
  //
  //Example: CatPrint(buf,"-LE");
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
}
