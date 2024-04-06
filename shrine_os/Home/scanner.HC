U0 SFlags(U8 *_dst_flags,U8 *lst,U8 *src)
{/*More than 64 flags. Flags passed by ref.

Examples:
$LK,"ScanFlags",A="FF:::/Adam/Opt/Utils/Diff.HC,ScanFlags:2"$(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),fu_flags);

I64 flags=0;
ScanFlags(&flags,"R\0L\0Dump\0Scan\0","+Dump-R"); //Sets Bit#2, Clears Bit#0.
*/
  I64 i;
  U8 *buf,*ptr;
  if (src) {
    buf=MAlloc(StrLen(src)+1);
    while (*src) {
      while (*src && *src!='+' && *src!='-')
	src++;
      if (*src=='+') {
	src++;
	if (*src) {
	  ptr=buf;
	  while (*src && *src!='+' && *src!='-' &&
		*src!=CH_SPACE && *src!=CH_SHIFT_SPACE)
	    *ptr++=*src++;
	  *ptr=0;
	  i=LstMatch(buf,lst);
	  if (i>=0)
	    LBts(_dst_flags,i);
	  else {
	    Free(buf);
	    throw('ScanFlag');
	  }
	}
      } else if (*src=='-') {
	src++;
	if (*src) {
	  ptr=buf;
	  while (*src && *src!='+' && *src!='-' &&
		*src!=CH_SPACE && *src!=CH_SHIFT_SPACE)
	    *ptr++=*src++;
	  *ptr=0;
	  i=LstMatch(buf,lst);
	  if (i>=0)
	    LBtr(_dst_flags,i);
	  else {
	    Free(buf);
	    throw('ScanFlag');
	  }
	}
      }
    }
    Free(buf);
  }
}
#define FLG_A 0x0000001 //a
#define FLG_B 0x0000002 //b

//U0 ScanFlags(U8 *_dst_flags,U8 *lst,U8 *src)
I64 flags=0;
SFlags(&flags,"a\0b\0c\0d","+ac");

"%d\n\n",flags;

if (flags&FLG_B) "yes\n\n"; else "no\n\n";

