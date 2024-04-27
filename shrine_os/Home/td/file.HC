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
U8* cur_drv() return Drv2Let(Fs->cur_dv); //Current drive letter.

F64 drv_free(U8 *drv='',Bool ret_free=FALSE)
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
 //Force format "C:"
  if (StrLen(drv)!=2) return FALSE;
  if (drv[1]!=58) return FALSE;

  return ToBool(Let2Drv(ToUpper(drv[0]),FALSE));
}

//Seemed to be Faster than IsDir(); for my case use.
Bool is_dir(CDirEntry *dir) return ToBool(dir->attr & RS_ATTR_DIR);

#define DRV  2
#define DIR  3
#define FILE 4

Bool type_got(U64 fvb,U64 type,U64 warg=0,Bool print_err=TRUE)
{
  Bool res=FALSE;

  if ((!(0<=warg<=1)) || 
      (!(DRV<=type<=FILE))) return FALSE;

  res=ToBool(fvb.u8[((warg<<2)+(type-(warg&1)))]);

  if (!res&&print_err)
  { 
    U64 err=0;

    if (type==DRV)  err=ERR_DIRFILEIDRV;
    if (type==DIR)  err=ERR_DRVFILEIDIR;
    if (type==FILE) err=ERR_DRVDIRIFILE;

    err_print(err,"info");
  }

  return res;
}
U0 type_exec(U64 fvb,U64 type,U64 warg=0,Bool print_err=TRUE,U8 *cmd,...)
{
  U8 *as=arg_str(argv,argc);
  if (argc) as=arg_str(argv,argc);
  else as=StrNew("");

  if (type_got(fvb,type,warg,print_err)) shell_exec(cmd,,as);
 
  Free(as);
}

Bool file_char(U8 *chr) return (LstMatch(chr," \0~\0*\0::\0-\0è",LMF_EXACT)>0);
Bool filenameOK(U8 *name) return FilesFindMatch(name,FILEMASK_TXT);

U64 files_valid(U8 *ddfa,U8 *ddfb)
{//Validate two given file arguments.
 //This was made primarily for templeDOS and no commands
 //will have more than two arguments and this lets me
 //save if it's valid and if it was a drv/dir/file.
 //
 //NOTE: Could be expanded to accept and use a fifo.
  U64 res=0;

  res.u8[2]=drv_mounted(ddfa);
  res.u8[3]=IsDir(ddfa);res.u8[3]=(res.u8[3]&(res.u8[2]^1));
  res.u8[4]=FileFind(ddfa);res.u8[4]=(res.u8[4]&(res.u8[3]^1));
  res.u8[0]=res.u8[2]|res.u8[3]|res.u8[4];

  res.u8[5]=drv_mounted(ddfb);
  res.u8[6]=IsDir(ddfb);res.u8[6]=(res.u8[6]&(res.u8[5]^1));
  res.u8[7]=FileFind(ddfb);res.u8[7]=(res.u8[7]&(res.u8[6]^1));
  res.u8[1]=res.u8[5]|res.u8[6]|res.u8[7];


  return res;
}
/*I64 ret=0;

//ret=files_valid(NULL,NULL);
//ret=files_valid("","~/valid.HC");
//ret=files_valid("~","~/valid.HC");
//ret=files_valid("1","~/valid.HC");
//ret=files_valid("9:","~/validu.HC");
//ret=files_valid("C:/Home","~/valid.HC");
//ret=files_valid("C:/Homez","~/valid.HC");
//ret=files_valid("C:/Home","~/valid.HC");
//ret=files_valid("a:","~/valid.HC");

"\n";
"ret.u8[0] %d\n",ret.u8[0];
"ret.u8[2]  DRV %d\n",ret.u8[2];
"ret.u8[3]  DIR %d\n",ret.u8[3];
"ret.u8[4] FILE %d\n",ret.u8[4];
"\n";
"ret.u8[1] %d\n",ret.u8[1];
"ret.u8[5]  DRV %d\n",ret.u8[5];
"ret.u8[6]  DIR %d\n",ret.u8[6];
"ret.u8[7] FILE %d\n",ret.u8[7];
"\n";

"Got %d\n",type_got(ret,DIR);
"Got %d\n",type_got(ret,DRV,1);
"\n";
*/
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

  if (id) "%8s","";
  else
  {
    if (entry->size >= gb)
      "%8d.%dg",entry->size/gb,
                 (entry->size-((entry->size/gb)*gb))/gt;
    else "%8d",entry->size;
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

    "$$MA,T=\"Listing\",LM=\"PopUpCd;ls;\"$$: %s\n",st;

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

    "%11d File(s) %10d byte(s)\n%11d Dir(s)",fc,bc,dc;

    DirTreeDel(entry);
  }
  else "No matching entries\n";

  Free(st);
}
