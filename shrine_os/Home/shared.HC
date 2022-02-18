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

/*shared.HC
  Description:
      Shared code file.
*/

//NOTE: MIGHT MOVE SOME OF THESE INTO THE OS FILES.

#define ERR_ARGC "Invalid number of arguments provided"
#define ERR_FLGC "Invalid number of options provided"
#define ERR_FLGI "Invalid option provided"
#define ERR_FILEFF "File / Directory found"
#define ERR_FILENF "File / Directory not found"
#define ERR_DRVIM "invalid drive specified or drive is not mounted"

U8 cur_drv()
{//Return the current drive letter.
    return Drv2Let(Fs->cur_dv);
}

Bool drv_valid(U8 *drv)
{//Valid mounted drive?
 //I cannot find any built-in functions, which didn't
 //throw exceptions if I tested a unmounted / non 
 //existent drive ... like 'z:'
  CDrv *dv;
  CBlkDev *bd;

  I64 i,drv_let;

  drv = ToUpper(drv);

  for (i=0,dv=blkdev.drvs;i<DRVS_NUM;i++,dv++) {
    if (dv->dv_signature==DRV_SIGNATURE_VAL) {
      bd=dv->bd;
      drv_let=Drv2Let(dv);
      if (drv_let == drv) {
        return TRUE;
      }
    }
  }

  return FALSE;
}

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

Bool IsDirChr(U8 *chr) {
  return (chr == '/' || chr == '~');
}

I64 ValidFiles(U8 *mask="11111111",...) 
{//Validate argv list of files & directories.
 //It uses a mask to determine, whether you want
 //to know, if it exists <1> or doesn't <0>.
 //
 //Usage: 
 //        ValidFiles("10",buffera,bufferb)
 //                    ^^
 //     buffera exists-||
 //                     -- bufferb doesn't 
 //



/*  U64 i = argc - 1;

  for (;i>=0;i--) {
    "%s %d\n",argv[i],FileFind(argv[i]) && mask[i];
    if (!(FileFind(argv[i]) && mask[i])) { //Is it a file?
      if (IsDir(argv[i]) && mask[i])  { //No, is it a directory?
        return FALSE;                   //Nope, non-valid
      }
    }
  }
*/

  return 1;
}

U64 HashCodeFor(U8 *str)
{//Hash code generator for strings.
 //This is a pretty weak one. I don't need much.
 //CRC16 would've been perfect for me. But, you
 //have to use big lookup table.
  U64 i = 0,
//  U64 g = 31, //Magic generator <- odd prime
   hash = 0;

  for (; i < StrLen(str); i++) {
    hash =  (hash << 2) + str[i];
//    hash =  ((hash << 5) - hash) + str[i]; //hash = g * hash + str[i];
  }

  return hash;
}

U8 tern(Bool condition, U64 *first, U64 *second)
{//Ternary operator like function.
  if (condition) return first;

  return second;
}


U0 shell_execute(U8 *cmd)
{//Execute a templeOS shell command.
  "\n"; ExePutS(cmd); "\n";
}
