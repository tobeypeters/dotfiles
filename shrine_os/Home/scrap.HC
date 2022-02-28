//"\n";
//
//drv_free;
//drv_free('C');
//"C free %7.2f%%\n",drv_free('C',TRUE);
//drv_free(,TRUE);
//
//"\n";

DocClear;

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

U64 *buffer = "viper armed";

U64 test = 124;

//"%s\n",buffer.u8[0]; //Sad I can't do this.
"%d\n",test.u8[0];     //Can do this.  guess, only works on numbers.

"\n";

KeyAndCont;
Exit;
