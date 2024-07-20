#include "./td/strings"
#include "./shared"

//"\n";
//
//drv_free;
//drv_free('C');
//"C free %7.2f%%\n",drv_free('C',TRUE);
//drv_free(,TRUE);
//
//"\n";

DocClear;

/*"IsDir(): %d %d %d %d\n",'-','~',IsDir("/"),IsDir("~");
"FileFind(): %d %d %d %d\n",'-','~',FileFind('/'),FileFind("~");
//And before you say duh ... you CAN use FileFind on
//MOST directories in TempleOS.  Unless, you set the appropriate flag.
//Things can always be overrided.  This was his grep function.
//$LK,"FUF_JUST_DIRS",A="MN:FUF_JUST_DIRS"$, $LK,"FUF_JUST_FILES",A="MN:FUF_JUST_FILES"$, $LK,"FUF_Z_OR_NOT_Z",A="MN:FUF_Z_OR_NOT_Z"$, $LK,"FUF_SCAN_PARENTS",A="MN:FUF_SCAN_PARENTS"$
"FileFind(\"\Demo\"): %d\n",FileFind("/Demo");*/

/*//Watch this:
"%d %d\n",'a','z'; //97 .. 122
"%d %d\n",*"a",*"z"; //97 .. 122
"%d %d\n",*"a:",*"z:"; //97 .. 122
"%d %d\n",*"a:/",*"z:/"; //97 .. 122*/
/*Bool drv_mounted(U8 *drv)
{//Valid mounted drive?
 //Better than using a built-in like
 // DrvIsWritable()? IDK ... Prob not.
  CDrv *dv;
  U64 i;
  drv = ToUpper(drv);
  for (i=0,dv=blkdev.drvs;i<DRVS_NUM;i++,dv++) {
    if (dv->dv_signature==DRV_SIGNATURE_VAL) {
      if (Drv2Let(dv) == drv) {
        return TRUE;
      }
    }
  }
  return FALSE;
}
I64 is_drv(U8 *drv)
{//Checks to see if drv points to a valid drive.
 //
 //Returns:
 //          -1 Not a valid drive.
 //           0 Drive is valid. But, not mounted.
 //           1 Drive is valid & mounted.
  U64 l = StrLen(drv);

  if (l == 2) {
    if (drv[1] == ':') {
      if (96<drv[0]<123 || 64<drv[0]<91) {
        return drv_mounted(drv[0]);
      }
    }
  }
  return -1;
}
"%d\n",is_drv("9:");
"%d\n",is_drv("Q:");
"%d\n",is_drv("B:");*/

//#include "shared"

/*if (-2) "-2 yeppers\n";
if (-1) "-1 yeppers\n";
if (-0) "-0 yeppers\n";
if (1)  "1 yeppers\n";
"%d\n",AbsI64(-1);
"%d\n",AbsI64(1);*/

/*#define HAS_File 1
#define HAS_Dir  2
#define HAS_Drv  4
U64 f = 0;
U64 *buffer = "viper armed";
f = HAS_Dir | HAS_File;
if (f&HAS_File) {
  "File yeppers\n";
}
if (f&HAS_Dir) {
  "Dir yeppers\n";
}
if (f&HAS_Drv) {
  "Drv yeppers\n";
}
buffer[1] = buffer[1] | HAS_File;
"%s\n",buffer[0];
if (buffer[1] & HAS_File) {
  "buffer[0] file yeppers\n";
}*/

/*U64 *buffer = "viper armed";
U64 test = 124;
//"%s\n",buffer.u8[0]; //Sad I can't do this.
"%d\n",test.u8[0];     //Can do this.  guess, only works on numbers.*/

/*#define TDf_D	0
#define TDf_F	1

DefineLstLoad("ST_TEMPLEDOS_FLAGS","d\0f\0");

Bool got_flag(U8 *flag_got, U64 flag_want, Bool err_disp = TRUE)
{
  I64 f = 0;

  //Think, this is how Terry does it.
  ScanFlags(&f,Define("ST_TEMPLEDOS_FLAGS"),flag_got);

  if (Bt(&f,flag_want)) {
    "yeppers\n";
  }
  else {
    "nope\n";
  }

  if (Bt(&f,flag_want)) return TRUE;

  if (err_disp) {
  }
  return FALSE;
}

U8 *testflag = "-f";
testflag[0]='+';
got_flag(testflag, TDf_F);

got_flag("+f", TDf_F);
got_flag("+f", TDf_D);
got_flag("+d", TDf_D);
got_flag("+d", TDf_F);*/


/*U64 sc = 32,
    scm = 255;

I64 MapValue(I64 x,I64 in_min,I64 in_max,I64 out_min,I64 out_max)
{
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

U64 HashSpotFor(U8 *str,U64 spots)
{//Hash code generator for strings.
 //This is a pretty weak one. I don't need much.
 //CRC16 would've been perfect for me. But, you
 //have to use big lookup table.

const int p = 31;
    const int m = 1e9 + 9;
    long long hash_value = 0;
    long long p_pow = 1;
    for (char c : s) {
        hash_value = (hash_value + (c - 'a' + 1) * p_pow) % m;
        p_pow = (p_pow * p) % m;
    }

  U64 i = 0,
//  U64 g = 31, //Magic generator <- odd prime
   hash = 0;

  for (;i < StrLen(str); i++) {
    hash =  (hash << 5) + str[i];
//    hash =  ((hash << 5) - hash) + str[i]; //hogash = g * hash + str[i];
  }

//  return hash % spots;
  return MapValue(hash % scm,0,scm,0,sc-1);
}

"cd    %d\n",HashSpotFor("cd",sc);
"df    %d\n",HashSpotFor("df",sc);
"ed    %d\n",HashSpotFor("ed",sc);
"cp    %d\n",HashSpotFor("cp",sc);
"fm    %d\n",HashSpotFor("fm",sc);
"ls    %d\n",HashSpotFor("ls",sc);
"mv    %d\n",HashSpotFor("mv",sc);
"rd    %d\n",HashSpotFor("rd",sc);
"rm    %d\n",HashSpotFor("rm",sc);
"cdd   %d\n",HashSpotFor("cdd",sc);
"cat   %d\n",HashSpotFor("cat",sc);
"cpu   %d\n",HashSpotFor("cpu",sc);
"man   %d\n",HashSpotFor("man",sc);
"mem   %d\n",HashSpotFor("mem",sc);
"now   %d\n",HashSpotFor("now",sc);
"run   %d\n",HashSpotFor("run",sc);
"vol   %d\n",HashSpotFor("vol",sc);
"date  %d\n",HashSpotFor("date",sc);
"help  %d\n",HashSpotFor("help",sc);
"dump  %d\n",HashSpotFor("dump",sc);
"exit  %d\n",HashSpotFor("exit",sc);
"grep  %d\n",HashSpotFor("grep",sc);
"more  %d\n",HashSpotFor("more",sc);
"quit  %d\n",HashSpotFor("quit",sc);
"time  %d\n",HashSpotFor("time",sc);
"tree  %d\n",HashSpotFor("tree",sc);
"view  %d\n",HashSpotFor("view",sc);
"clear %d\n",HashSpotFor("clear",sc);
"mkdir %d\n",HashSpotFor("mkdir",sc);
"rmdir %d\n",HashSpotFor("rmdir",sc);
"touch %d\n",HashSpotFor("touch",sc);
"tasks %d\n",HashSpotFor("tasks",sc);*/

/*
F64 test = 123456789;
I64 test2 = Ceil(Log10(test));

"length of test: %d\n",test2;*/

/*U64 sc = 512,
    scm = 255;

I64 MapValue(I64 x,I64 in_min,I64 in_max,I64 out_min,I64 out_max)
{
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

U64 HashSpotFor(U8 *str,U64 spots)
{
  U64 hash = 5381,
      c = 0,
      i = 0;

  for (;i < StrLen(str); i++) {
    hash = ((hash << 5) + hash) + str[i];
  }

  return (hash % sc) % 32;
}

"cd    %d\n",HashSpotFor("cd",sc);
"df    %d\n",HashSpotFor("df",sc);
"ed    %d\n",HashSpotFor("ed",sc);
"cp    %d\n",HashSpotFor("cp",sc);
"fm    %d\n",HashSpotFor("fm",sc);
"ls    %d\n",HashSpotFor("ls",sc);
"mv    %d\n",HashSpotFor("mv",sc);
"rd    %d\n",HashSpotFor("rd",sc);
"rm    %d\n",HashSpotFor("rm",sc);
"cdd   %d\n",HashSpotFor("cdd",sc);
"cat   %d\n",HashSpotFor("cat",sc);
"cpu   %d\n",HashSpotFor("cpu",sc);
"man   %d\n",HashSpotFor("man",sc);
"mem   %d\n",HashSpotFor("mem",sc);
"now   %d\n",HashSpotFor("now",sc);
"run   %d\n",HashSpotFor("run",sc);
"vol   %d\n",HashSpotFor("vol",sc);
"date  %d\n",HashSpotFor("date",sc);
"help  %d\n",HashSpotFor("help",sc);
"dump  %d\n",HashSpotFor("dump",sc);
"exit  %d\n",HashSpotFor("exit",sc);
"grep  %d\n",HashSpotFor("grep",sc);
"more  %d\n",HashSpotFor("more",sc);
"quit  %d\n",HashSpotFor("quit",sc);
"time  %d\n",HashSpotFor("time",sc);
"tree  %d\n",HashSpotFor("tree",sc);
"view  %d\n",HashSpotFor("view",sc);
"clear %d\n",HashSpotFor("clear",sc);
"mkdir %d\n",HashSpotFor("mkdir",sc);
"rmdir %d\n",HashSpotFor("rmdir",sc);
"touch %d\n",HashSpotFor("touch",sc);
"tasks %d\n",HashSpotFor("tasks",sc);*/

/*#define REC_CNT 32
#define REC_OVR 10
#define REC_TOT REC_CNT+REC_OVR
U8 *VSAM[REC_TOT][7] =
{
/*
  Very poor implementation, of a hashtable.
  See how I waste memory & stuff.
  HASH, command, token min, token max,
  validate file(s) / dir{s}, flag min,
  flag max
*/

{  0,  "view", 2, 2,  TRUE, 0, 0},
{  1,   "man", 2, 2, FALSE, 0, 0},
{  2,      "", 0, 0, FALSE, 0, 0},
{  3,  "date", 1, 1, FALSE, 0, 0},
{  4,    "ls", 1, 2,  TRUE, 0, 0},
{  5,      "", 0, 0, FALSE, 0, 0},
{  6,      "", 0, 0, FALSE, 0, 0},
{  7,      "", 0, 0, FALSE, 0, 0},
{  8,    "mv", 1, 1, FALSE, 0, 0},
{  9,      "", 0, 0, FALSE, 0, 0},
{ 10,      "", 0, 0, FALSE, 0, 0},
{ 11, "tasks", 1, 1, FALSE, 0, 0},
{ 12,    "cd", 1, 2,  TRUE, 0, 0},
{ 13,   "cpu", 1, 1, FALSE, 0, 1},
{ 14,    "ed", 2, 2, FALSE, 0, 0},
{ 15,    "df", 1, 1, FALSE, 0, 0},
{ 16,   "cdd", 1, 2,  TRUE, 0, 0},
{ 17,      "", 0, 0, FALSE, 0, 0},
{ 18,      "", 0, 0, FALSE, 0, 0},
{ 19,  "grep", 2, 2, FALSE, 0, 0},
{ 20,  "time", 1, 1, FALSE, 0, 0},
{ 21,  "tree", 1, 3,  TRUE, 0, 1},
{ 22,   "vol", 1, 1, FALSE, 0, 0},
{ 23,      "", 0, 0, FALSE, 0, 0},
{ 24,    "cp", 3, 3, FALSE, 0, 1},
{ 25,   "now", 1, 1, FALSE, 0, 0},
{ 26,   "run", 2, 2,  TRUE, 0, 0},
{ 27,    "rd", 2, 2,  TRUE, 0, 1},
{ 28, "mkdir", 2, 2, FALSE, 0, 0},
{ 29,   "cat", 2, 2,  TRUE, 0, 0},
{ 30,      "", 0, 0, FALSE, 0, 0},
{ 31,  "exit", 1, 1, FALSE, 0, 0},

{  3, "rmdir", 2, 2,  TRUE, 0, 1},
{  4,   "mem", 1, 1, FALSE, 0, 0},
{  4,    "rm", 2, 2,  TRUE, 0, 1},
{  8,  "quit", 1, 1, FALSE, 0, 0},
{  8, "touch", 2, 2, FALSE, 0, 0},
{ 12, "clear", 1, 1, FALSE, 0, 0},
{ 14,  "help", 1, 1, FALSE, 0, 0},
{ 24,    "fm", 1, 3,  TRUE, 0, 1},
{ 24,  "more", 2, 2,  TRUE, 0, 0},
{ 27,  "dump", 2, 2,  TRUE, 0, 0}

};


U64 sum_str(U8 *sum_of)
{//Iterate over each char of a string and
 //return the numeric sum of all the chars.

  U64 sum = 0,
        l = 0,
        i = 0;

  if ((l = StrLen(sum_of)) == 0) return 0;

  for (;i<l;i++) {
    sum += sum_of[i];
  }

  return sum;
}

U64 i = 0;

"\n";
for (;i<REC_TOT;i++) {
//  "sum of [%s]: %d\n", VSAM[i][1],5 sum_str(VSAM[i][1]);
  "%d %s\n",sum_str(VSAM[i][1]),VSAM[i][1];
}*/


/*I64 str_cmp(U8 *stra, U8 *strb) {
  while ((*stra && *strb) && (*stra == *strb))  {
    stra++; strb++;
  }

  return tern((*stra - *strb) == 0,1,0);
}


U8 *a = "car", *b = "caro", *c = "";

"%d\n",str_cmp(a,b);

if (str_cmp(a,b)) {
  "yes\n";
}*/

//fmt_size(1073741825);
//fmt_size(1395864371);

//my_dir;


//F64 test = 1;
//F64 a = 128;

//I64 b = 0;

//"%f %f %d\n",test,a,b;

//b = ClampI64(ToI64(a * test),0,255);

//"%f %f %d\n",test,a,b;

//#help_index "pubext"
//U0 pubext() {
//  "pubext\n";
//}

//I64 age=12;
//if (13<=age<20) "teenager\n";
//else "Not a teenager\n";



//Mouse over a position and press "i" to zoom in, "o" to zoom out
//Mouse over a position and press "i" to zoom in, "o" to zoom out
// Keys 1-4 change mapping of iteration values (requires calc)
//keys 6-9 change palettes (instant, no recalc)
//Press "m" to double the max iterations
//Press "p" to toggle printing coords of center, scale and max iterations to screen

/*
CBGR48 gr_palette_std[16]={
0x000000000000,0x00000000AAAA,0x0000AAAA0000,0x0000AAAAAAAA,
0xAAAA00000000,0xAAAA0000AAAA,0xAAAA55550000,0xAAAAAAAAAAAA,
0x555555555555,0x55555555FFFF,0x5555FFFF5555,0x5555FFFFFFFF,
0xFFFF55555555,0xFFFF5555FFFF,0xFFFFFFFF5555,0xFFFFFFFFFFFF};
*/
//Converts RGB triplets of values (0-63) to CBGR48 TempleOS color value
/*CBGR48 RGB2C(U64 red, U64 green, U64 blue) {
  CBGR48 col=0;

  col.r=ClampI64(red,0,63)<<10;
  col.g=ClampI64(green,0,63)<<10;
  col.b=ClampI64(blue,0,63)<<10;

  "%X \n",col;

  return col;
}
RGB2C(63,63,63); //Should be 359428E8 ... but, getting FC00FC00FC00
RGB2C(0,63,0);
RGB2C(0,0,63);


U64 MAP_TYPE=0;
//U64 PALETTE_TYPE=0;

U64 ColorMapper(U64 in=0) {
  if (in==0) return 0;

  switch[MAP_TYPE] {
  case 0:
   return 1+(in%15);
  case 2:
   return 1+Sqrt(in)%15;
   }
}

//U0 PaletteMapper(){
//}
*/

//U8 *mask=MStrPrint("%s/*","C:/Home");
//"mask: %s\n",mask;
//Free(mask);
/*
F64 drv_free(U8 *drv = '', Bool ret_free=FALSE)
{//Display free space for each mounted drive
 //or a specified mounted drive
 //Or reeturn the free space, for a specific mounted drive.
  CDrv *dv;
  I64 c = 0,
      i = 0;
  F64 s = 0;

  for (i=0;i<26;i++) {
    if ((dv=Let2Drv(i+'A',FALSE)) &&
	  (dv->fs_type==FSt_FAT32 || dv->fs_type==FSt_REDSEA)) {
      c = Drv2Let(dv);
      s = DrvUnused(c)*100.0/(dv->size*BLK_SIZE);

      if (drv == '' && !ret_free) {
        "%C: %7.2f%% Free\n",c,s;
      }
      else {
        if (drv == c) {
          if (drv == c && ret_free) return s;

         "%C: %7.2f%% Free\n",c,s;
          return 0;
        }
      }
    }
  }
}
drv_free;
*/
/*
U8 *p[50][50];
*p=CAlloc(sizeof(U8)*50*50);

U0 parse(U8 *cmd)
{
  U64 c=StrOcc(cmd,' ');
  "%d %s\n",c,cmd;

  U64 i=0;
  for (;i<c;i++)
  {
    StrFirstRem(cmd," ",p[i]);
    "%s p[%d]\n",p[i],i;
  }
  StrCpy(p[i],cmd);
  "%s p[%d]\n",p[i],i;
}

U0 main()
{
  U8 *cmd;
  while (TRUE)
  {
    "> ";
    cmd=GetStr(,,GSF_SHIFT_ESC_EXIT);

    if (StrLen(cmd)>0){
      StrUtil(cmd, SUF_REM_LEADING);
      StrUtil(cmd, SUF_REM_TRAILING);
    }

    if(!(StrCmp(MStrUtil(cmd,SUF_TO_UPPER),"EXIT"))) break;

    parse(cmd);

    MemSet(cmd, '\0', sizeof(U8)*StrLen(cmd));
    MemSet(p, '\0', sizeof(U8)*StrLen(p));
  }
  Free(cmd);
}
main();
MemSet(p, '\0', sizeof(U8)*StrLen(p));
Free(p);
*/

//Bool IsDurp(U8 *dir_name)
//{//Is a str a valid, existing Dir?
//  U8 *mask=MStrPrint("%s/*",dir_name);
//  Bool res=FALSE;

//  U64 len=StrLen(dir_name);
//  if (!len) goto cleanup;
//  if (len>=2) {
//   if (dir_name[1]==':') {
//     U64 drv=ToUpper(dir_name[0]);
//     if (!('A'<=drv<='Z')) goto cleanup;
//     if (!Let2Drv(drv,FALSE)) goto cleanup;
//   }
//  }

//  Bool old_silent=Silent;
//  CDirContext *dirc;
//  if (dirc=DirContextNew(mask)) {
//    DirContextDel(dirc);
//    res=TRUE;
//  }

//  Silent(old_silent);
//cleanup:
//  Free(mask);
//  return res;
//}

//if (IsDurp('')) "yes\n"; else "no\n";
//if (IsDurp("")) "yes\n"; else "no\n";
//if (IsDurp("~")) "yes\n"; else "no\n";
//if (IsDurp("/")) "yes\n"; else "no\n";
//if (IsDurp("c")) "yes\n"; else "no\n";
//if (IsDurp("C:")) "yes\n"; else "no\n";
//if (IsDurp("1")) "yes\n"; else "no\n";
//if (IsDurp("e:")) "yes\n"; else "no\n";

/*U8 old[4]="car";
"%s\n",old;
U8 *new=CAlloc(sizof(U8)*2);
new[0]=old[0]; //Doesn't work
//new=StrNew(char[0]); //Doesn't work
//new=StrNew("c"); //Works just like expected
"%s\n",new;
Free(new);
*/

//"LstMatch: %d\n",LstMatch("o","~\0*\0::\0",LMF_EXACT);
//public U0 HijackFunc(U8 *orig, U8 *new)
//{// Replace a system function with a new function
//
//    // Warning old function address is not saved and this overwrites it!
//    // Assembly code of old function is patched to jump to new instead.
//    // Only a reboot will restore the original function!
//    PUSHFD
//    CLI
//    *orig=0xe9;
//    *(orig+1)(U32*)=new-orig-5;
//    POPFD
//}

//CTask *task;
//while (TRUE) {
//  task=Fs->next_task;
//  while (task!=Fs) {
//    "$$MA+X,T=\"Task:%08X:%16ts\",LM=\"0x%08X\n\"$$\n",
//     task,task->task_name,task;
//     task=task->next_task;
//  }
//  break;
//}

//U0 static_test3() {
//  static U64 i=69;

//  "i: %d\n",i;
//  i=70;
//}

//static_test3;
//static_test3;

/*U8 *callocit(...)
{
  U64 len=0,
        i=0;

  while (i<argc) {
   len+=str_len(argv[i]);
   i++;
  }

  return CAlloc((sizeof(U8)*len)+1);
}

U8 *test=callocit("three","four");

str_cat(test,,"three ","four");

"%s %d\n",test,str_len(test);

Free(test);*/

/*U8 *strnew(U8 *buf=NULL,CTask *mem_task=NULL,...)
{//Accepts a $LK,"CTask",A="MN:CTask"$ or $LK,"CHeapCtrl",A="MN:CHeapCtrl"$.NULL allocs off current task's heap.
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

done:
  return res;
}

U8 *buffe$IV,0$r=strnew(,,"viper","armed");
"buffer: %s\n",buffer;
Free(buffer);*/

$SP,"<1>",BI=1$$ER$

//https://www.deviantart.com/mariiboops/art/8x8-Pixel-Characters-838322593

KeyAndCont;
        ƒ                                                ÿ                                                         ÿ                         	             	            ÿ                         	             	            ÿ                                	                   ÿ                                	            ÿ                                                        ÿ                   	                  	      ÿ             