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

/*file.HC
  Description:
      File system related functions.
*/

#include "~/td/strings"

//Return the current drive letter.
U8 cur_drv() return Drv2Let(Fs->cur_dv);

F64 drv_free(U8 *drv='', Bool ret_free=FALSE)
{//Display free space for each mounted drive
 //or a specified mounted drive.
 //Or just return the free space, for a specific mounted drive.
  CDrv *dv;
  U64 d=26,
       c=0,
       i=0;

  F64 s = 0;

  for (;i<d;i++) {
    if (drv)
      dv=Let2Drv(ToUpper(drv),FALSE);
    else
      dv=Let2Drv(i+'A',FALSE);

    if (dv && (dv->fs_type==FSt_FAT32 || dv->fs_type==FSt_REDSEA))
    {
      c = Drv2Let(dv);
      s = DrvUnused(c)*100.0/(dv->size*BLK_SIZE);

      if (drv && ret_free) return s;

      "%C: %3.2f%% Free\n",c,s;
      if (drv) break;
    }
  }
  return 0;
}

Bool drv_mounted(U8 *drv)
{//Valid mounted drive. Must be passed in 
  if ((!drv) || 
      (!(StrLen(drv)==2))) return FALSE; //Force format "C:"

  return ToBool(Let2Drv(ToUpper(drv[0]),FALSE));
}

//Seemed to be Faster than IsDir(); for my case use.
Bool is_dir(CDirEntry *dir) return ToBool(dir->attr & RS_ATTR_DIR);
Bool is_dirEX(U8 *dir_name)
{//Is a str a valid, existing Dir?
 //Had to wrap this in a try, IsDir throws exceptions
  try return IsDir(dir_name);
  catch return FALSE;
}

I64 valid_files(U8 *mask="11111111",...) 
{//Validate argv list of drives, files & directories.
 //It uses a mask to determine, whether you want
 //to know, if it exists <1> or doesn't <0>.
 //
 //Usage: 
 //        valid_files("10",buffera,bufferb);
 //
 //returns:
 //         1	All files are valid
 //      -IDX	IDX where it failed in negative form.
 //
 //         When you check the return value in an if,
 //         you need to make sure you do:

 //CAMEBACKINHEREANDTRYINGTOFIGUREOUTWHY???
 //I MADETHIS.BUT,REALIZEDITWASSOiCOULDVALID
 //WHATEVERINEEDEDANDEASILYRETURNWHICHEVERONE
 //ISINVALID. SOICOULDDISPLAYITINTHEERRORMESSAGE.
 //THINK, I WAS GOING TO JUST SET BITS OF AN I64. THIS IS
 //SIMPLIER AND NO FUNCTION CALLS.


  I64 i=0,
      x=0;

  for (;i<argc;i++)
  {
//    x.u8[0]=drv_mounted(argv[i]);
//    "x.u[0]: %d   mounted %s\n",x.u8[0],argv[i];
//    x.u8[1]=is_dirEX(argv[i]);
//    "x.u[1]: %d directory %s\n",x.u8[1],argv[i];

//FileFindEX(argv[i]);

//  else if (!CFileNameTo(dname,name))
//    PrintErr("Invalid FileName: \"%s\".\n",name);

    try {
x.u8[2]=FileFind(argv[i]);
} catch {x.u8[2]=0;}

//    x.u8[2]=try FileFind(argv[i]); catch 
//    "x.u[2]: %d      file %s\n",x.u8[2],argv[i];
    "\n";

"%d\n",mask;
//    if ((x.u8[0] || x.u8[1] || x.u8[2]) != mask[i]-48) {
//      return 0 - i; //Return a "FALSE" value
//    }
  }
  return 1;
}
valid_files(,"~/test.HC","~/valid.HC","c:");

#define gb 1073741824
#define gt gb / 10
#define STD "ST_DAYS_OF_WEEK"
#define STM "ST_MONTHS"

U0 tree_top(U8 *name) { "$$TR,\"%s\"$$",name; "$$ID,2$$"; }
U0 tree_trunk() "$$ID,-2S$$";

U0 ls_dir_link(U8 *dirname,U8 *full_name=NULL)
{//Put $LK,"DolDoc",A="FI:::/Doc/DolDocOverview.DD"$ dir macro to StdOut, $LK,"DocPut",A="MN:DocPut"$.
  U8 *st;
  if (!dirname) return;
  if (IsRaw)
    "%s",dirname;
  else {
    if (!full_name)
      full_name=st=DirNameAbs(dirname);
    else
      st=NULL;
    "$$MA,T=\"%s\",LM=\"Cd(\\\"%s\\\");ls;\n\"$$",dirname,full_name;
    Free(st);
  }
}

U0 ls_entry_info(CDirEntry *entry=NULL)
{
  if (!entry) return;

  CDateStruct ds, dsc;
  Date2Struct(&dsc,Now+local_time_offset);

  Bool id = is_dir(entry);

  Date2Struct(&ds,entry->datetime+local_time_offset);

  "%c ",100-(!id*55);

  if (id) "%9s","";
  else
  {
    if (entry->size >= gb)
      "%9d.%dg",entry->size/gb,
                 (entry->size-((entry->size/gb)*gb))/gt;
    else "%9d",entry->size;
  }

  " %03tZ %02d ",ds.mon-1,STM,ds.day_of_mon;

  if (ds.year<dsc.year) "%5d",ds.year;
  else "%02d:%02d",ds.hour,ds.min;

  " ";
  if (!id) PutFileLink(entry->name,entry->full_name);

  return;
}
U0 ls_dir_sub(CDirEntry *entry)
{
  CDirEntry *temp=entry;

  "\n";

  while (entry)
  {
    if (!str_cmpEX(entry->name,,".",".."))
    {
      "\n";
      ls_entry_info(entry);
      if (is_dir(entry))
      {
        tree_top(entry->name);        
        ls_dir_sub(FilesFind(entry->full_name,FUF_RECURSE));
        tree_trunk;
      }
    }
    entry=entry->next;
  }
  entry=temp;

  "\n";

  DirTreeDel(entry);

  return;
}
U0 ls(U8 *files_find_mask='*',Bool tree_mode=FALSE)
{//Linux'ish style directory listing.
  U8 *st;

  if (!(st=DirCur))
  {
    PrintErr("Invalid Drive\n");
    return;
  }

  CDirEntry *entry=FilesFind(files_find_mask),
            *start=NULL;

  if (entry)
  {
    st=MAllocIdent(entry->full_name);
    StrLastRem(st,"/");

    if (!st[2]) StrCpy(st+2,"/");

    "$$MA,T=\"Listing\",LM=\"PopUpCd;ls;\n\"$$: %s\n",st;

    I64 fc=0,
        dc=0,
        bc=0;

    Bool id=FALSE;

    start=entry;
    while (entry)
    {
      id=is_dir(entry);

      ls_entry_info(entry);

      if (id)
      {
        dc+=1;

        if (tree_mode)
        {
          if (!str_cmpEX(entry->name,,".",".."))
          {
            "$$LTBLUE$$";
            tree_top(entry->name);
            ls_dir_sub(FilesFind(entry->full_name));
            tree_trunk;
            "$$FG$$";
          }
          else "%s",entry->name;
        }
        else
        {
          ls_dir_link(entry->name,entry->full_name);
        }
      }
      else
      {
        fc+=1; bc+=entry->size;
      }

      "\n";

      entry=entry->next;
    }
    entry=start;

    "%11d File(s) %10d byte(s)\n%11d Dir(s)\n\n",fc,bc,dc;

    DirTreeDel(entry);
  }
  else "No matching entries\n";

  Free(st);
}

