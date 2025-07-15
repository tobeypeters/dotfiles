//#include "./td/strings"
//#include "./shared"

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

$ER$$ER$

//https://www.deviantart.com/mariiboops/art/8x8-Pixel-Characters-838322593

/*U0 Main()
{
  U8 *Menu_Select=NULL;
  U8 *input=NULL;

 menu:
  "\nMain Menu\n";
  "------ --\n";
  "1. Run\n";
  "2. Exit\n\n";

  Menu_Select=GetStr("Would you like to run this program?: ");

  if (*Menu_Select=='1') goto run_game;
  if (*Menu_Select=='2') goto term_game;
  else goto menu;

 run_game:
  DocClear;
  input=GetStr("\nWhat is your name?: ");
  "\n\n%s is a silly egghead!\n\n\n\n\n\n\n\n\n",input;
  PressAKey();
  term_game:
  "\n";

}

Main();
*/
/*asm {
  FINDER::
    PUSH RBP
    MOV  RBP,RSP
    MOV  RAX,"Find"
    CALL &Find
    LEAVE
    RET
}
Call(FINDER);*/

/*U64 v=0;

v.u8[0]=1;
v.u8[3]=1;

"%064b\n",v;
"%d\n",v;*/

/*U8 *buffer=PopUpPickDir;
"---\n";
"--- %s\n",buffer;
"---\n";*/

/*U8 *rev_str(U8 *str)
{//Reverse a string.  I thought, TempleOS had one.
 //I can't find it. If there's one buried in the OS,
 //I'll get rid of this one.
 //I'm not using the normal swapping algorithm here.
  U64 l=StrLen(str)-1,i=0;
  U8 *st=CAlloc(sizeof(U8)*l);

  for (;i<=l;i++) *(st+i)=str[l-i];

  return st;
}

"reversed string: %s\n\n",rev_str("reverse");
*/

/*U8 *opt_state="ON\0OFF\0";

"%d\n",LstMatch("a",opt_state,LMF_IGNORE_CASE);
"%d\n",LstMatch("on",opt_state,LMF_IGNORE_CASE);
"%d\n",LstMatch("off",opt_state,LMF_IGNORE_CASE);
*/

//Works perfect
/*I64 options[4]={1,1,1,1};

U0 i64array() {
  //Gives a missing expression error
  I64 options[4]={1,1,1,1};;
}
*/

/*U64 x,y;

if (x=1||y=1) {
  "x: %d y: %d\n",x,y;
}
*/

/*U64 i=10;
switch (i) {
case 0...4:
  '.';
  break;
case 5...9:
  '*';
  break;

default:
  '+';
}
*/

/*CD3 p1,p2;

p1.x=10;
p1.y=10;
p1.z=0;

"%f\n%f\n%f\n",p1.x,p1.y,p1.z;

p2.x=20;
p2.y=20;
p2.z=0;

"%f\n%f\n%f\n",p2.x,p2.y,p2.z;
"dist: %d\n",ToI64(D3Dist(&p1,&p2));
//Use Sqrt and not just Sqr ....
F64 el=Sqrt((p2.x-p1.x)*(p2.x-p1.x)+(p2.y-p1.y)*(p2.y-p1.y));
"dist2: %f\n",el;

//"%f\n",p1.x;*/

/*CD3 test(U64 a,U64 c)
{
  CD3 *v=MAlloc(sizeof(CD3));

  v->x=a;
  v->y=c;

  return v;
}

CD3 *t;
t=test(10,20);
"%2.8f %2.8f\n",t->x,t->y;
Free(t);*/

/*I32 a=10;

a*=3284157443;

"%d\n",a;*/

/*U0 rain(U8 *bow) {
  if (*bow) "yes\n";
}
rain("");*/
/*
U0 test()
{
  U32 a=10*3284157443;

  //Prints $WW+H,1$a: 32841574430 ToU32(a): 2776803358
  "a: %d ToU32(a): %d\n",a,ToU32(a);
}
test;
*/
/*CD2 a,c;

a.x=14;a.y=16;
c.x=34;c.y=35;

"%2.8f\n",D3Dot(&a,&c);*/

//CD2 a={14,16};
//"%2.2f %2.2f\n",a.x,a.y;

/*F64 ATan3(F64 y,F64 x)
{
  F64 angle=0;

  if (x==0)
  {
    if (y>0) return �/2; //90degrees
    if (y<0) return -�/2; //-90degrees
    else return 0;
  }

  angle=ATan(y/x);

  if (x>0) return angle; //quad 1 or 4
  if (x<0&&y>=0) return angle+�; //quad 2
  else return angle-�;           //quad 3
}

"%2.3f\n",ATan3(1,1);
"%2.3f\n",ATan3(-1,1);
"%2.3f\n",ATan3(1,-1);
"%2.3f\n",ATan3(-1,-1);
"%2.3f\n",ATan3(0,0);
*/
/*F64 rotation_x,rotation_y;

CD3 *newCD3(F64 x,F64 y,F64 z) {
  CD3 *ret=MAlloc(sizeof(CD3));
  ret->x=x+8;
  ret->y=y+8;
  ret->z=z+8;
  return ret;
}
U0 rp(CD3 *rp,I64 *rx,I64 *ry,I64 *rz) {
  F64 cos_x=Cos(rotation_x),
       cos_y=Cos(rotation_y),
       sin_x=Sin(rotation_x),
       sin_y=Sin(rotation_y),
          y1=cos_x*rp->y-sin_x*rp->z,
          z1=sin_x*rp->y+cos_x*rp->z,
          x2=cos_y*rp->x+sin_y*z1,
          z2=-sin_y*rp->x+cos_y*z1;

  rx=x2;ry=y1;rz=z2;
}
CD3 *test=newCD3(-1,-0.13385827,-0.16535433);
U64 WIDTH=640,
   HEIGHT=480;

I64 px,py,pz;

test=rp(test,&x,&y,&z);
U64 sx=(px* WIDTH/4)+WIDTH/2;
    sy=(py* HEIGHT/4)+HEIGHT/2;

printf("{-1,-0.13385827,-0.16535433},%2.8f,%2.8f %d %d\n",rotation_x,rotation_y,sx,sy);*/

/*U0 ih(U64 idx)
{
  U64 i,ii,im;

  i=idx.u8[0];
  ii=idx.u8[1];
  im=i+ii;

//  "%d %d\n",i,ii;

  for (;i<im;i++) {
    "i: %d\n",i;
  }
}

U64 in,dim=100,hm=25;

in.u8[1]=25;

in.u8[0]=0;
ih(in);
in.u8[0]=25;
ih(in);
in.u8[0]=50;
ih(in);
in.u8[0]=75;
ih(in);*/

/*#define DIM 97

U64 bc,bcf,br,i;

U0 Init_Helper(U64 idx)
{
  U64 i=idx.u8[0],
     lc=i+idx.u8[1];

  for (;i<lc;i++)
  {
    "%d\n",i;
  }
}

bc=DIM/(mp_cnt);
br=DIM-(bc*(mp_cnt));

for(i=0;i<mp_cnt;i++)
{
  bcf.u8[0]=i*bc;
  bcf.u8[1]=bc+((i+1==mp_cnt)*br);
  Init_Helper(bcf);
}*/

/*

U0 SwapFuncs(U8 *funca,U8 *funcb)
{//Equivalent of HijackFun();
  CHash* result=HashFind(funca,Fs->hash_table,HTT_FUN);

  if (result && (result->type & HTT_FUN)!=0)
  {
    "result\n";
    result(CHashFun *)->exe_addr=funcb;
  }
}

CHashFun* FindFunction(U8* name) {
  CHash* result = HashFind(name, Fs->hash_table, HTT_FUN);

  if (result && (result->type & HTT_FUN) != 0)
    return result(CHashFun *);
  else
    return NULL;
}

U0 tester() { "Tester ...\n"; };

CHashFun *chf=FindFunction("Cdr");
chf->exe_addr=&tester;
Cdr;*/

/*F64 rotation_x=0,
    rotation_y=0,
    x,y,z;

CD3 p;

p.x=2;
p.y=0;
p.z=0;

U0 rot(CD3 *rp,F64 *ux,F64 *uy,F64 *uz)
{
  F64 cos_x=Cos(rotation_x),
       cos_y=Cos(rotation_y),
       sin_x=Sin(rotation_x),
       sin_y=Sin(rotation_y),
          y1=cos_x*rp->y-sin_x*rp->z,
          z1=sin_x*rp->y+cos_x*rp->z,
          x2=cos_y*rp->x+sin_y*z1,
          z2=-sin_y*rp->x+cos_y*z1;

  *ux=x2;*uy=y1;*uz=z2;
}

rot(&p,&x,&y,&z);

"%2.8f %2.8f %2.8f\n",x,y,z;*/

/*U0 mptest(I64 cnt)
{
  Adam("\"\n\n$$LTCYAN$$:..%d..:$$FG$$ ...\n\n\";",cnt);
}
ADocClear;
Spawn(&mptest,5,"mptest",,Fs);
*/

/*#define DIM 129

U64 i;

i.u8[0]=DIM/mp_cnt;
i.u8[1]=DIM-i*mp_cnt;
"%d %d\n",i.u8[0],i.u8[1];
*/

/*F64 test=2/3;
"%2.8f\n",test;

if (2/3<0) "yes\n";
if (test<0) "yes\n";
*/
/*public U8 ToLower(U8 chr)
{//Convert a char to lowercase
  if (InRangeI64(chr,'A','Z'))
    return chr+32;
  return chr;
}

"%c\n",ToLower('*');*/

/*U0 ACDirList()
{
  CDirEntry *tmpde,*tmpde1;

  U8 *st=MAlloc(sizeof(U8)*(1000*256)); //Larger then we need.

  tmpde=tmpde1=FilesFind('*',
        FUF_RECURSE|FUF_JUST_TXT|FUF_JUST_FILES);
  while (tmpde) {
    st=MStrPrint("%s\n%s",st,tmpde->full_name);
    tmpde=tmpde->next;
  }

  FileWrite("~/ac_dirlist.DD",st,StrLen(st));

  DirTreeDel(tmpde1);
}

ACDirList;*/

/*U64 i=sys_code_bp->alloced_u8s-sys_code_bp->used_u8s;

  if (sys_data_bp)
    i+=sys_data_bp->alloced_u8s-sys_data_bp->used_u8s;

"Mem:%010X\n",i;
*/

/*U8  buf[15]="Big Bufford\n";
U8 *buf2=MAllocIdent(&buf);
"" buf2;
Free(buf2);
*/
/*
I64 *TupleI64(...)
{//Build a compressed Tuple, out of up to 8 numbers.
  I64 it=-1;

  if (0<argc>8) return it;

  for (;argc>0;argc--)
    it.u8[argc-1]=argv[argc-1];

  return it;
}

//The return value of TupleI64, should be be checked for -1.
//Cause, each .u8 will be equal to 255.
I64 tup=TupleI64(67,68,69,70,71,72,73,76);
"tup: [%d] %d %d %d\n\n",tup,tup.u8[0],tup.u8[1],tup.u8[2];

U8 Tuple(U8 *fmt,...)
{
  if (argc==0) return NULL;

  fmt=MStrPrint("%%s %s",fmt);
  U8 *st=NULL;

  U64 i;

  for (i=0;i<argc;i++)
    st=MStrPrint(fmt,st,argv[i]);

  return StrUtil(st,SUF_REM_LEADING|SUF_REM_TRAILING|SUF_TO_UPPER);
}
*/
//I64/U64 tuple
/*U8 *buf3=Tuple("%d",68,69);
I64 aa, bb;
"buf3: [%s]\n",buf3;
StrScan(buf3,"%d %d",&aa,&bb);
"buf3: [%d %d]\n\n",aa,bb;
Free(buf3);

U8 *buf4=Tuple("%s","hello","world");
"buf4: [%s]\n",buf4;
U8 *buf5=MAlloc(sizeof(U8)*128),
   *buf6=MAlloc(sizeof(U8)*128);
StrScan(buf4,"%s %s",&buf5,&buf6);
"buf4: [%s %s]\n\n",buf5,buf6;
Free(buf4);Free(buf5);Free(buf6);
*/
/*U8 *p=MAlloc(sizeof(U8)*256);

U0 buff_add(U8 *buf, U8 *str)
{//Assign a string to buffer.
  MemSet(buf,'\0',sizeof(buf));
  StrCpy(buf,str);
}
buff_add(p,StrNew(PopUpPickDir));

"p: %s\n",p;

Free(p);
*/

/*U0 test(I64 mode=FM_NORMAL)
{
  AdamLog("%d\n",mode);
}

U0 test2(I64 mode=FM_NORMAL)
{
test(mode);
}

test2(FM_PICK_DIRFILE);
*/

//U8 p[512];

//StrCpy(p,"C:/Home");
//"%s\n",p;
//CatPrint(p,"/*.*");
//"%s\n",p;

/*I64 res=StrCmp("aa","bb");
"%d %d\n",res,!res;

if (!res) "yes\n";
*/

/*U64 l=StrLen(test);
U64 c=0,i=0;
U8 *buf[StrOcc(test,",")+1];

while (l)
{
"test: %s\n",test;
  i=StrFirstOcc(test,',');

"i: %d\n",i;

//  test[i=StrFirstOcc(test,',')]='\0';
"test: %s\n",test;
  l--;
}

"%s %d\n",test,l;
*/

/*
//Build an array of strings
U8 *StrSplit(U8 *src2)
{//Split a comma csv. into an array
  U8 *src=StrNew(src2);

  U64 parts=StrOcc(src,',')+1,
         lb=StrLen(src),i=0;

  U8 **arr=MAlloc(sizeof(U8 *)*parts);
  for (i=0;i<parts;i++)
    arr[i]=CAlloc(lb);

  i=0;
  while (StrLen(src))
  {
    StrFirstRem(src,",",arr[i]);
    i++;
  }

  return Tuple("%d",parts,arr);
}

U8 *buff="Hello,World,Terry,is,king,...";
U8 *buff2=StrSplit(buff);
U64 len;U8 **sp;
StrScan(buff2,"%d %d",&len,&sp);
"StrSplit Example:\n";
"\n%h9cbuff2: %s\n  Array length: [%d]\n Array Pointer: [%d]\n\n",32,buff,len,sp;

U64 j=0;
for (;j<len;j++)
  "%h8csp[%d] : %s\n",32,j,sp[j];
"\n";
Free(buff2);
Free(sp);
*/
/*
U8 *StrIns(U8 *src,U8 *part,U64 idx)
{//Insert a string into another
//  return *st=MStrPrint("%h*c%s",pl,32,src);

  U64 pl=StrLen(part);

  U8 *st=MStrPrint("%h*c%s",pl,32,src);
  U8 *st=MStrPrint("%h*c%s",pl,32,src);

  MemCpy(st,src,idx); MemCpy(st+idx,part,pl);

  return st;
}

"String Insert Example:\n";
U8 *buff3="Hello WorldTerry is king...";
U8 *buff4=StrIns(buff3,"! ",11);
"Orig String: %s\n",buff3;
" New String: %s\n",buff4;
Free(buff4);
*/
/*
U8 *StrIt(U8 *str,U8 *add,I64 idx)
{
/*
  U8 buffer[128];

  //HolyC : Inside a function set the memory
  MemSet(buffer,'\0',sizeof(buffer));

  MemCpy(buffer,str,StrLen(str));
//  "buffer: %s\n",buffer;

//  Modify buffer however you want ...

//  return StrNew(buffer);
//  return MStrPrint("%s",buffer);

*/
  U64 ls=StrLen(str);

  if (!ls) return NULL;

  idx=Clamp(idx,0,ls);

  //Gonna treat this like an array.
  U8 *st=MStrPrint("%h*c",ls+StrLen(add),32);
  MemCpy(st,str,ls);


  U64 len_st=StrLen(st),
           i=idx,j=0,si=idx;

  while (i<len_st)
  {
    if (i==idx)
    {
      while (add[j]!='\0') {
        st[i]=add[j];
        i++;j++;
      }
      i--;si--;
    }
    else st[i]=str[si];

    i++;si++;
  }

  return st;
}

"%s\n",StrIt("HelloWorld","] .. [",-1);
*/
/*
Bool IsNum(U8 *chr)
{
  U8 *p=chr;
  U64 err_cnt=0;

  while (*p)
  {
    if (!Bt(char_bmp_dec_numeric,p[0]))
    {
      switch (p[0])
      {
        case 45:
          if (*p!=*chr) return FALSE;

          err_cnt.u8[0]++;
          break;
        case 46:
	  err_cnt.u8[1]++;
          break;
        default:
          return FALSE;
          break;
      }
      if (err_cnt.u8[0]>1||
          err_cnt.u8[1]>1) return FALSE;
    }
    p++;
  }

  return TRUE;
}
U8 *tfa[2]={"FALSE","TRUE"};

"\n";
"IsNum: %s\n",tfa[IsNum("35..4")]; //FALSE
"IsNum: %s\n",tfa[IsNum("..5.4")]; //FALSE
"IsNum: %s\n",tfa[IsNum("0")];     //TRUE
"IsNum: %s\n",tfa[IsNum("-23")];   //TRUE
"IsNum: %s\n",tfa[IsNum("2-3")];   //FALSE
"IsNum: %s\n",tfa[IsNum("-23.5")]; //TRUE
"IsNum: %s\n",tfa[IsNum("-23.5a")];//FALSE
"IsNum: %s\n",tfa[IsNum("a")];     //FALSE
"IsNum: %s\n",tfa[IsNum("A")];     //FALSE
"IsNum: %s\n",tfa[IsNum("A1.2")];  //FALSE
"IsNum: %s\n",tfa[IsNum("1,2A")];  //FALSE
"IsNum: %s\n",tfa[IsNum("23.")];   //TRUE
"\n";
*/

/*Bool isNum(U8 *c){
    U64 a=0,l=StrLen(c);

    if (StrOcc(c,'.')>1||
	(a.u8[0]=StrOcc(c,'-'))>1||
	(a.u8[1]=StrOcc(c,'+'))>1) return FALSE;

    if (a>256) return FALSE;
 
    //+ & - position check
    if (a.u8[0]&&c[0]!='-' ||
        a.u8[1]&&c[0]!='+') return FALSE;

    for(a=0;a<l;a++){
	if (!('0'<=c[a]<='9' ||
             c[a]=='.' || c[a]=='-' || 
             c[a]=='+')) {return FALSE;}
    }

    return TRUE;
}

"isNum: %d \n\n",isNum("3ds1416");
"isNum: %d \n\n",isNum("-3.1416");
"isNum: %d \n\n",isNum("+3.1416");
"isNum: %d \n\n",isNum("++3.1416");
"isNum: %d \n\n",isNum("3.1-416"); //ADDED
*/

/*U8 buffer[128]="Hello";
CatPrint(&buffer," World!");
"%s\n",buffer;*/

//KeyAndCont;
