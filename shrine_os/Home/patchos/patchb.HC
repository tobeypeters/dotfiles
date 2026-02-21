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

/*patchb.HC
  Description:
      Adds new functions to the system.
*/
#help_index "Patched"

Bool WALL_DEBUG=FALSE,
     WALL_CPU,WALL_MEM,
     WALL_FPS;
I64  WALL_DEBUG_VAL=0;

WALL_FPS=WALL_MEM=WALL_CPU=TRUE;

U8 *tf_arr[2]={"FALSE","TRUE"};

#help_index "Mouse"
public U0 MouseXY(CTask *task,U64 *x,U64 *y)
{
  *x=ms.pos.x-task->pix_left;
  *y=ms.pos.y-task->pix_top;
}
#help_index ""

#help_index "Math"
public F64 ATan2(F64 y,F64 x)
{//Two number Arc Tangent (Inverse Tan) or four quads.
  F64 angle=0;

  if (x==0)
  {
    if (y>0) return ã/2; //90degrees
    if (y<0) return -ã/2; //-90degrees
    else return 0;
  }

  angle=ATan(y/x);

  if (x>0) return angle; //quad 1 or 4
  if (x<0&&y>=0) return angle+ã; //quad 2
  else return angle-ã;           //quad 3
}
public Bool I64Cmp(I64 num,...)
{//Check to see if an I64 is in a given argv list.
  if (argc==0) return FALSE;

  U64 i=0;

  for (;i<argc;i++) {
    if (num==argv[i])
      return TRUE;
  }
  return FALSE;
}
public Bool IsNan(F64 NaN) return ToBool(NaN!=NaN);

public Bool InRangeI64(I64 val,I64 min,I64 max)
{//Take a I64 number and determine if it's in a given range.
  return min<=val<=max;
}
public F64 MapF64(F64 value,F64 in_min,F64 in_max,F64 out_min,F64 out_max)
{//Take a F64 number from one range and scale it to a different range.
  return (value-in_min)*(out_max-out_min)/(in_max-in_min)+out_min;
}
public I64 MapI64(I64 value,I64 in_min,I64 in_max,I64 out_min,I64 out_max)
{//Take a I64 number from one range and scale it to a different range.
  return ((value-in_min)*(out_max-out_min)+(in_max-in_min)/2)/(in_max-in_min)+out_min;
}
public U32 ToU32(U32 vu)
{/* Return a valid U32. Functions treat everything as 64bit.
  Bit level is ignored, if it's not inside a function.

  U0 test()
  {
    U32 a=10*3284157443;

    //Prints $WW+H,1$a: 32841574430 ToU32(a): 2776803358
    "a: %d ToU32(a): %d\n",a,ToU32(a);
  }
  test;
*/
  return vu;
}
public I64 *TupleI64(...)
{//Build a compressed Tuple, out of up to 8 numbers.
  I64 it=-1;

  if (0<argc>8) return it;

  for (;argc>0;argc--)
    it.u8[argc-1]=argv[argc-1];

  return it;
}

public U8 Tuple(U8 *fmt,...)
{
  if (argc==0) return NULL;

  fmt=MStrPrint("%%s %s",fmt);
  U8 *st=NULL;

  U64 i;

  for (i=0;i<argc;i++)
    st=MStrPrint(fmt,st,argv[i]);

  return StrUtil(st,SUF_REM_LEADING|SUF_REM_TRAILING|SUF_TO_UPPER);
}
public U32 Range(U32 min=0,U32 max)
{//Return a number, in a given range.
  U64 base=RandU64;
  U32 range_size=max-min+1;
  U32 limit=U32_MAX-(U32_MAX%range_size);
  U32 result;

  do {
    result=base(U32);
    base>>=32;
  } while (result>=limit);

  return min+(result%range_size);
}
public U64 gcd(U64 num1,U64 num2)
{//Get the greatest common denominator of two numbers.
  if (num2==0) return num1;
  return gcd(num2,num1%num2);
}
public U64 PowerOf2(U64 num) return ToBool(num>0&&!(num&(num-1)));
#help_index ""

#help_index "Char/Conversion"
public U8 ToLower(U8 chr)
{//Cvt char to lower case.
  if (InRangeI64(chr,'A','Z'))
    return chr+32;
  return chr;
}
#help_index ""

#help_index "Char/Operations"
public Bool IsDigit(U8 *chr) return Bt(char_bmp_dec_numeric,chr);

public I64 StrCmpEX(U8 *str,Bool ignore_case=FALSE,...)
{//Compare a string, to a list of strings.
  I64 res=-1;

  if (!str||argc<1) return res;

  while (argc-->0)
  {
    if (ignore_case)
      res=StrICmp(str,argv[argc]);
    else
      res=StrCmp(str,argv[argc]);

    if (res==0) break;
  }

  return res;
}
public U8 *StrNQ(U8 *str)
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

public U8 StrUpper(U8 *str)
{//Convert a string to uppercase.
  return MStrUtil(str,SUF_TO_UPPER);
}
public U8 StrLower(U8 *str)
{//Convert a string to lowercase. 
  return MStrUtil(str,SUF_TO_LOWER);
}
public U8 *StrRev(U8 *str)
{//Reverse a string.
  U64 l=StrLen(str)-1,i=0;
  U8 *st=CAlloc(sizeof(U8)*l);

  for (;i<=l;i++) *(st+i)=str[l-i];

  /*Inplace swap
  U8 *m=&str[0],*n=&str[l];

  while (m<n)
  {
    l=*n;
    *n--=*m;
    *m++=l;
  }*/

  return st;
}
public U64 StrOccEx(U8 *str,...)
{//Count occurrences of a char or set of chars.
 //You can count up to 8 diffent chars. Providing more
 //will just return 0. The counts are all stored
 //in the sub-ints of a U64 n.u8[0]-n.u8[7]
  U64 res=0,
        i=0;

  if (!str||!(1<=argc<9)) return res;

  while (argc-->0)
  {
    res.u8[i]=StrOcc(str,argv[i]); i++;
  }

  return res;
}
#help_index ""

#help_index "Memory/Heap"
public U8 *CAllocSized(U64 size=0,...)
{//Accepts a $LK,"CTask",A="MN:CTask"$ or $LK,"CHeapCtrl",A="MN:CHeapCtrl"$.NULL allocs off current task's heap.
 //CAlloc'd size is calculated, from length of strings in argv or can
 //be simply passed in.

  U64 len=size,
        i=0;

  while (i<argc) {
   len+=StrLen(argv[i]);
   i++;
  }

  return CAlloc(sizeof(U8)*len+1);
}
#help_index ""

#help_index "Char/Operations;Memory"
public U8 *StrCat(U8 *dst,Bool flush=TRUE,...)
{//Build a str, from strings stored in argv.
 //flush clears the buffer first. This way,
 //keeps you from using a fmt string  & needing to know the 
 //the format of it.
  U64 i = 0;

  if (flush) *dst = '\0';

  for (;i<argc;i++) {
    CatPrint(dst,argv[i]);
  }

  return dst;
}
public U0 pmemsave(U8* file)
{//QEMU Monitor <ctrl><shift><2> utility to transfer a file with pmemsave.
 //Author: Alec8023 on TempleOS Discord server.
    CDirEntry* dt = FilesFind(file);
    if (!dt) {
        return;
    }
    CDirEntry* de = dt;
    CBlkDev* bd;
    I64 let;
    while (de) {
        let = *de->full_name;
        if (Let2BlkDevType(let) == BDT_RAM) {
            bd = Let2BlkDev(let);
            "pmemsave 0x%08x 0x%08x %s\n", bd->RAM_dsk(U64) + (de->clus * BLK_SIZE), de->size, de->name;
        }
        de = de->next;
    }
    DirTreeDel(dt);
}
#help_index ""

#help_index "DolDoc"
public U0 ADocClear()
{//Clear Adams doc window
  Adam("DocClear;");
}
public U0 Cdr()
{//Change to the root directory of the current drive
  Cd("/");
}
#help_index ""

public Bool I64InLst(I64 inval,...)
{//Check to see if an I64 is in a given argv list.
  U64 i=0;

  for (;i<argc;i++) {
    if (inval==argv[i])
      return TRUE;
  }
  return FALSE;
}

#help_index "Keyboard Devices;Char/Input;StdIn"
public U0 KeyAndCont()
{//Print "Press any key to continue ..." and wait for non-zero $$LK,"ASCII",A="MN:CH_CTRLA"$$ key.
 //Doesn't print any newline characters and "clears" the line after you
 //press a key.
  "$FG,2$Press any key to continue ...$FG$";

  GetChar(,FALSE);
  PutChars(CH_CTRLY);
}
#help_index ""

public U8 *ExtFilename(U8 *str)
{//Extracts filename "file.HC" from say an absolute path "C:/Home/file.HC" 
  U8 *buffer;

  if (buffer=StrLastOcc(str, "/"))
    return buffer+1;
  else
    return str;
}

#help_index "AutoComplete/Dictionary"
public U0 acdwordsload() {}
public U0 ACDirList()
{//Adds current directory filenames to the autocomplete
  CDirEntry *tmpde,*tmpde1;

  CHashAC *tmpw;

  U8 *buffer;

  tmpde=tmpde1=FilesFind("./*",FUF_JUST_FILES);
  while (tmpde) {
    buffer=StrNew(ExtFilename(tmpde->full_name));
//    FileExtRem(buffer,buffext);

    tmpw=HashFind(buffer,ac.hash_table,HTT_WORD);
    if (!tmpw) {
      tmpw=ACAlloc(sizeof(CHashAC));
      tmpw->str=AStrNew(buffer);
      tmpw->type=HTT_WORD;
      tmpw->use_cnt=1;
      tmpw->hits=1;
      HashAdd(tmpw,ac.hash_table);
      ac.num_words++;
    }

    Free(buffer);

    tmpde=tmpde->next;
  }

  DirTreeDel(tmpde1);
}
#help_index ""

#help_index "Graphics/GR Files;"\
	"File/Cmd Line (Typically);DolDoc/Cmd Line (Typically);"\
	"StdOut;Cmd Line (Typically)"
public U64 LineCnt(U8 *filename)
{//Get the line count, for a specified file.
  U64 res=0;
  CDirEntry *tmpde=NULL;
  if (tmpde=FilesFind(filename)) {
    res=LineRep1(tmpde);
    DirTreeDel(tmpde);
  }
  return res;
}
public U0 More(U8 *filename,U64 prn_lines=U64_MAX,Bool less=FALSE)
{//Output txt or graphic file to the command line,
 //one screen at a time.
 //prn_lines limits the line count
  if (!FileFind(filename)) return;

  U8 *buffer=NULL;

  I64 size=0;

  buffer=FileRead(filename,&size,DOCF_PLAIN_TEXT);

  U64 ml=Fs->win_bottom-Fs->win_top,
      cl=0, //Current line count
      dc=0; //Display count

  Bool di=FALSE; //Display the char(s)

  U64 lc=LineCnt(filename)-prn_lines;

  while(*buffer!=TK_EOF)
  {
    if (less) di=(cl>=lc);
    else di=(cl<prn_lines);

    if (di) {
      "%c",*buffer;
      if (cl==prn_lines) break;
    }

    if (*buffer=='\n') { cl++; dc+=di; }

    if (di)
      if (dc==ml) { KeyAndCont; dc=0; }

    buffer++;
  }

  "\n";
}
public U0 Head(U8 *filename,U64 disp=10)
{//Print out the first 10 lines, of the specified file.
  More(filename,disp);
}
public U0 Tail(U8 *filename,U64 disp=10)
{//Print out the last 10 lines, of the specified file.
  More(filename,disp,TRUE);
}
#help_index ""

#help_index "Debug"
public U0 DebugSND() Noise(1000,75,1000);
public U0 DebugYN(Bool state) { if (state) "YES"; else "NO"; "\n"; }
public U0 DebugPRN(U8 *dbg_STMNT,Bool preLF=FALSE,Bool postLF=FALSE,Bool adam=FALSE)
{
  U8 *buffer=CAlloc(sizeof(U8)*255);

  CatPrint(buffer,"%c$$LTCYAN$$debug$$FG$$: $$LTRED$$%s$$FG$$%c",
           preLF*'\n',dbg_STMNT,postLF*'\n');

  if (adam) AdamLog("%s\n",buffer);
  else "%s\n",buffer;

  Free(buffer);
}
#help_index ""

#help_index "File/Cmd Line (Typically);Cmd Line (Typically)"
public U8 *CurDrv() return Drv2Let(Fs->cur_dv); //Current drive letter.

public F64 DrvFree(U8 *drv='',Bool ret_free=FALSE)
{//Display free space for each mounted drive
 //or a specified mounted drive.
 //Or just return the free space, for a specific mounted drive.
  CDrv *dv;
  U64 d=26,
       c=0,
       i=0;

  F64 s=0;

  for (;i<d;i++) {
    if (drv)
      dv=Let2Drv(ToUpper(drv),FALSE);
    else
      dv=Let2Drv(i+'A',FALSE);

    if (dv&&(dv->fs_type==FSt_FAT32 || dv->fs_type==FSt_REDSEA))
    {
      c=Drv2Let(dv);
      s=DrvUnused(c)*100.0/(dv->size*BLK_SIZE);

      if (drv&&ret_free) return s;

      "%C: %3.2f%% Free\n",c,s;
      if (drv) break;
    }
  }
  return 0;
}
public Bool DrvMounted(U8 *drv)
{//Valid mounted drive. Must be passed in
 //Force format "C:"
  if (StrLen(drv)!=2) return FALSE;
  if (drv[1]!=58) return FALSE;

  return ToBool(Let2Drv(ToUpper(drv[0]),FALSE));
}

#define TRASH_DIR "/Trash"
#define TRASH 127

public U0 trash_msg(U8 *msg,Bool silent_off=OFF)
{//Display a specified message, when a file or files
 //are sent to the trash.
 Silent(silent_off); "Trashed: %s",msg;
}

public U0 dump_exists()
{//Make sure the /Trash directory exists on the current drive
  if (!IsDir(TRASH_DIR)) DirMk(TRASH_DIR);
}
#help_index ""

//If you want you code to be ran
public Bool AdamIncluding(CTask *task) return task!=adam_task;
