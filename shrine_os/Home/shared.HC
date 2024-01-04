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

#define HAS_File 1
#define HAS_Dir  2
#define HAS_Drv  4

#define ERR_ARGC "Invalid number of arguments provided"
#define ERR_FLGC "Invalid number of options provided"
#define ERR_FLGI "Invalid option provided"
#define ERR_FILEAF "File / Directory already exists"
#define ERR_FILEFF "File / Directory found"
#define ERR_FILENF "File / Directory not found"
#define ERR_DRVIM "Invalid drive specified or drive is not mounted"
#define ERR_DIRIFILE "Directory provided instead of a file"
#define ERR_FILEIDIR "File provided instead of a directory"
#define ERR_UNKNOWN "Unrecognized command provided"

Bool I64_IN(I64 inval,...)
{//Check to see if an I64 is in a given argv list.
  U64 i = 0;

  for (;i<argc;i++) {
    if (inval == argv[i]) {
      return TRUE;
    }
  }

  return FALSE;
}

U8 tern(Bool condition, U64 *first, U64 *second)
{//Ternary operator like function.
  if (condition) return first;

  return second;
}

U8 cur_drv()
{//Return the current drive letter.
  return Drv2Let(Fs->cur_dv);
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

Bool drv_mounted(U8 *drv)
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
 //          -2 Right format, not a drive. Like ... 9:
 //          -1 Wrong format. File or Directory name probably provided.
 //           0 Drive is valid. But, not mounted.
 //           1 Drive is valid & mounted.
  U64 l = StrLen(drv);

  if (l == 2) {
  if (drv[1] == ':') {
    if (96<drv[0]<123 || 64<drv[0]<91) {
      return drv_mounted(drv[0]);
    }
    else {
      return -2;
    }
  }
  }

  return -1;
}

I64 ValidFiles(U8 *mask="11111111",...) 
{//Validate argv list of drives, files & directories.
 //It uses a mask to determine, whether you want
 //to know, if it exists <1> or doesn't <0>.
 //
 //Usage: 
 //        ValidFiles("10",buffera,bufferb);
 //                    ^^
 //     buffera exists-||
 //                     -- bufferb doesn't 
 //
 //        if (ValidFiles(blah,blah) == 1) {}
 //
 //returns:
 //         1	All files are valid
 //      -IDX	IDX where it failed in negative form.
 //
 //         When you check the return value in an if,
 //         you need to make sure you do:
 //
 //
  I64 i = 0,
      x = 0;

  for (;i<argc;i++) {
    x.u16[0] = is_drv(argv[i])==1;
    
    if (!(x.u16[1] = IsDir(argv[i]))) {
      x.u16[2] = FileFind(argv[i]);
    }

//    "x.u16[0]: %d x.u16[1]: %d x.u16[2]: %d mask[i]-48: %d\n",
//    x.u16[0],x.u16[1],x.u16[2], mask[i]-48;


    if ((x.u16[0] || x.u16[1] || x.u16[2]) != mask[i]-48) {
      return 0 - i;
    }
  }

  return 1;
}

U64 HashCodeFor(U8 *str)
{//Hash code generator for strings.
  U64 hash = 5381,
      i = 0;
  
  for (;i < StrLen(str); i++) {
    hash = ((hash << 5) + hash) + str[i];
  }

  return (hash % 512) % 32;
}

U0 shell_execute(U8 *cmd)
{//Execute a templeOS shell command.
  "\n"; ExePutS(cmd); "\n";
}

U0 viewer(U8 *cmd)
{//Execute a specified command and examine the results
 //in "view" mode.
  DocClear; DocTop;
  ExePutS(cmd);
  "$$BK,1$$Press ESC to exit ...$$BK,0$$";
  DocTop;View; DocBottom;
  PutChars(CH_CTRLY);
}

U0 strcat(U8 **buffer,Bool flush=TRUE,...)
{//Build a str, from strings stored in argv.
 //flush=TRUE ... buffer will be cleared first.
  U64 i = 0;

  if (flush) *buffer = '\0';

  for (;i<argc;i++) {
    CatPrint(buffer,argv[i]);
  }
}

U0 my_scanflags(U8 *_dst_flags,U8 *lst,U8 *src)
{ //Stripped down version, of ScanFlags.
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
	  while (*src && *src!='+' && *src!='-' &&
		*src!=CH_SPACE && *src!=CH_SHIFT_SPACE)
	    *ptr++=*src++;
	  *ptr=0;
	  i=LstMatch(buf,lst);
	  if (i>=0)
	    LBts(_dst_flags,i);
	}
      }
    }
    Free(buf);
  }
}

I64 MapValue(I64 x,I64 in_min,I64 in_max,I64 out_min,I64 out_max)
{//Map one range to another range.
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
U8 str_upper(U8 *stra)
{//Can't find a uppercase function for strings. 
 //There's ToUpper, but it looks like it's for
 //single characters.
  return MStrUtil(stra,SUF_TO_UPPER);
}
U8 str_lower(U8 *stra)
{//Can't find a lowerrcase function for strings. 
  return MStrUtil(stra,SUF_TO_LOWER);
}

Bool str_cmp(U8 *stra, U8 *strb, Bool ignore_case=FALSE)
{//StrCmp replacement which returns TRUE & FALSE.
 //Saying !StrCmp() for TRUE, erks me ...
/*Bool str_cmp(U8 *stra, U8 *strb) {
  if (StrLen(stra) != StrLen(strb)) return FALSE;
 
  U8 *sp1 = stra, *sp2 = strb;
  Bool ret_val = TRUE;
 
  while (stra && stra[0] != '\0') {
    if (!(stra[0] == strb[0])) ret_val = FALSE;
 
    stra++; strb++;
  }
 
  stra = sp1; strb = sp2;

  return ret_val;
}*/
  
  Bool result = FALSE;
  if (ignore_case) {
    result = (!(StrICmp(stra,strb)));
  }
  else { 
    result = (!(StrCmp(stra,strb)));
  }

  return result;
}

U0 zero_mem(U8 *region, U64 size)
{//Zero out a memory range.
  MemSet(region, '\0', sizeof(U8)*size);
}

#define REVBUF_CNT 64
U8 num_str(U64 number)
{//Convert a number to a string.
  U64 tmp = 0,
        i = 0,
        j = 0;

  U8 *buffer[REVBUF_CNT];
  zero_mem(buffer,REVBUF_CNT);

  i = REVBUF_CNT - 1;

  while (number>0) {
    tmp = number % 10;

    buffer[i] = tmp;
    number /= 10;

    i--;
  }

  i++;

  while (i < REVBUF_CNT) {
    buffer[j] = 48 + buffer[i];
    i++; j++;
  }

  return buffer;
}

#define gigabyte 1073741824
#define gigatenth gigabyte / 10
#define STD "ST_DAYS_OF_WEEK"
#define STM "ST_MONTHS"

U0 my_dir(U8 *files_find_mask='*')
{//Linux'ish style directory listing.
  CDirEntry *tmpde1=NULL,*tmpde2;
  tmpde1=FilesFind(files_find_mask);

  U8 *st;

  if (!(st=DirCur))
    PrintErr("Invalid Drive\n");
  else {
    if (tmpde1) {
      st=MAllocIdent(tmpde1->full_name);
      StrLastRem(st,"/");

      if (!st[2]) StrCpy(st+2,"/");

//      "Listing: $$MA,T=\"%s\",LM=\"MiniFM;\n\"$$\n",st;
//      "$$MA,T=\"Directory\",LM=\"PopUpCd;Dir;\n\"$$of%s\n",st;

      "Listing: $$MA,T=\"%s\",LM=\"\"$$\n",st;

      CDateStruct ds, dsc;
      Date2Struct(&dsc,Now+local_time_offset);

      U64 gt = gigatenth,
           g = gigabyte;

      Bool id = FALSE;
             
      while (tmpde1) {
	tmpde2=tmpde1->next;

	Date2Struct(&ds,tmpde1->datetime+local_time_offset);

	id =tmpde1->attr & RS_ATTR_DIR;

	"%c ",100-(!id*55);

	if (id) {
	  "%9s",""; goto dir;
	}

	if (tmpde1->size >= gigabyte)
	  "%9d.%dg",tmpde1->size/g,
		    (tmpde1->size-((tmpde1->size/g)*g))/gt;
	else "%9d",tmpde1->size;

	dir:
	  " %03tZ %02d ",ds.mon-1,STM,ds.day_of_mon;

	  if (ds.year<dsc.year) "%5d",ds.year;
	  else "%02d:%02d",ds.hour,ds.min;

	  " ";

	  if (id)
	    PutDirLink(tmpde1->name,tmpde1->full_name);
	  else
	    PutFileLink(tmpde1->name,tmpde1->full_name);
	  "\n";
	  DirEntryDel(tmpde1);
	  tmpde1=tmpde2;
      }
    } else
      "No matching entries\n";
    Free(st);
  }
}
U0 ls(U8 *files_find_mask='*')
{//Linux'ish style directory listing.
  U8 *st;

  if (!(st=DirCur))
  {
    PrintErr("Invalid Drive\n");
    return;
  }

  CDirEntry *tmpde1=NULL,*tmpde2;
  tmpde1=FilesFind(files_find_mask);


  if (tmpde1) 
  {
    st=MAllocIdent(tmpde1->full_name);
    StrLastRem(st,"/");

    if (!st[2]) StrCpy(st+2,"/");

//      "Listing: $$MA,T=\"%s\",LM=\"MiniFM;\n\"$$\n",st;
//      "$$MA,T=\"Directory\",LM=\"PopUpCd;Dir;\n\"$$of%s\n",st;

    "$$MA,T=\"Listing\",LM=\"PopUpCd;Dir;\n\"$$: %s\n",st;

    CDateStruct ds, dsc;
    Date2Struct(&dsc,Now+local_time_offset);

    U64 gt = gigatenth,
         g = gigabyte;

    I64 fc = 0,
        dc = 0,
        bc = 0;

    Bool id = FALSE;
             
    while (tmpde1)
    {
      tmpde2=tmpde1->next;

      Date2Struct(&ds,tmpde1->datetime+local_time_offset);

      id =tmpde1->attr & RS_ATTR_DIR;

      "%c ",100-(!id*55);

      if (id)
      {
        "%9s",""; goto dir;
      }

      if (tmpde1->size >= gigabyte)
        "%9d.%dg",tmpde1->size/g,
                 (tmpde1->size-((tmpde1->size/g)*g))/gt;
      else "%9d",tmpde1->size;

      dir:
        " %03tZ %02d ",ds.mon-1,STM,ds.day_of_mon;

        if (ds.year<dsc.year) "%5d",ds.year;
        else "%02d:%02d",ds.hour,ds.min;

        " ";

        if (id)
        {
          PutDirLink(tmpde1->name,tmpde1->full_name);
          dc+=1;
        }
        else
        {
          PutFileLink(tmpde1->name,tmpde1->full_name);
          fc+=1;
          bc+=tmpde1->size;
        }

        "\n";

        DirEntryDel(tmpde1);

        tmpde1=tmpde2;
    }
    "%11d File(s) %10dbytes\n%11d Dir(s)\n",fc,bc,dc;
  }
  else "No matching entries\n";

  Free(st);

//  }

}
ls;

