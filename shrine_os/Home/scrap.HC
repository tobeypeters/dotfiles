//"\n";
//
//drv_free;
//drv_free('C');
//"C free %7.2f%%\n",drv_free('C',TRUE);
//drv_free(,TRUE);
//
//"\n";

//DocClear;

"\n";

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


U64 sc = 32;

U64 HashSpotFor(U8 *str,U64 spots)
{//Hash code generator for strings.
 //This is a pretty weak one. I don't need much.
 //CRC16 would've been perfect for me. But, you
 //have to use big lookup table.
  U64 i = 0,
//  U64 g = 31, //Magic generator <- odd prime
   hash = 0;

  for (;i < StrLen(str); i++) {
    hash =  (hash << 2) + str[i];
//    hash =  ((hash << 5) - hash) + str[i]; //hash = g * hash + str[i];
  }

  return hash % spots;
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
"tasks %d\n",HashSpotFor("tasks",sc);


"\n";

//KeyAndCont;

//Exit;
