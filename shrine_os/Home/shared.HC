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
U8 *str_cat(U8 **buffer,Bool flush=TRUE,...)
{//Build a str, from strings stored in argv.
 //flush=TRUE ... buffer will be cleared first.
  U64 i = 0;

  if (flush) *buffer = '\0';

  for (;i<argc;i++) {
    CatPrint(buffer,argv[i]);
  }

  return buffer;
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
  Bool result = FALSE;

  if (ignore_case) {
    result = (!(StrICmp(stra,strb)));
  }
  else { 
    result = (!(StrCmp(stra,strb)));
  }

  return result;
}

Bool str_cmpEX(U8 *cmp_to,Bool ignore_case=FALSE, ...)
{//StrCmp replacement which returns TRUE & FALSE.
 //Saying !StrCmp() for TRUE, erks me ...
 //Expanded to compare a string to a list of strings.
 //
 //Example: if (!str_cmpEX(entry->name,,".","..")) { ... }
  if (!cmp_to || (argc < 1)) return FALSE;


  Bool result = FALSE;

  I64 i = 0;
  for (;i<argc;i++) {
    result = str_cmp(cmp_to,argv[i],ignore_case);

    if (result) break;
  }


  return result;
}

//I'm duplicating a lot of code here. :<
//I want to pull out all the changes, I've made
//to templeOS files and put them in my own files.
//But, I need to finish templeOS v1.0 and refactor/
//restructure the code.  Everything is a mess.
U8 MyGetStr(I64 flags=0)
{//$LK,"Flags",A="MN:GSF_SHIFT_ESC_EXIT"$
  CDoc *doc;
  CDocEntry *doc_e,*doc_e_end;
  U8 *st,*st2,*res;
  I64 ch,sc;
  "$$PT$$";
  do {
    ch=DocGetKey(&sc);
    if (ch==CH_ESC) {
      if (doc=DocPut) {
	DocLock(doc);
	if (doc->doc_signature==DOC_SIGNATURE_VAL && doc->cur_entry!=doc) {
	  doc_e=DocEntryCopy(doc,doc->cur_entry);
	  DocBottom(doc);
	  DocEntryRun(doc,doc_e,TRUE);
	  DocEntryDel(doc,doc_e);
	}
	DocUnlock(doc);
      }
      if (flags&GSF_WITH_NEW_LINE)
	break;
    } if (ch==CH_SHIFT_ESC) {
      if (flags&GSF_SHIFT_ESC_EXIT) {
        //Think this messes up windows which is opened by
        //templedos_task.  I believe, I can later determine
        //if it's a child window or not.  If so I can,do Exit;
        res = StrNew("-1");
        goto gs_done;
      }
      else {
	res=StrNew("");
	goto gs_done;
      }
    }
//<CTRL-SHIFT-ENTER> is a blank line without entry
  } while (flags&GSF_WITH_NEW_LINE || ch!='\n' ||
	sc&SCF_CTRL && sc&SCF_SHIFT);

  doc=DocPut;
  DocLock(doc);
  if (flags&GSF_WITH_NEW_LINE) {
    doc_e=doc->cur_entry;
    do doc_e=doc_e->last;
    while (doc_e!=doc && doc_e->type_u8!=DOCT_PMT);
    doc_e=doc_e->next;
    if (res=DocScanLine(doc,doc_e,NULL,&doc_e_end)) {
      while (doc_e_end!=doc && doc_e_end->type_u8==DOCT_NEW_LINE) {
	st2=MStrPrint("%s\n",res);
	Free(res);
	res=st2;
	if (st=DocScanLine(doc,doc_e_end->next,NULL,&doc_e_end)) {
	  st2=MStrPrint("%s%s",res,st);
	  Free(st);
	  Free(res);
	  res=st2;
	}
      }
    }
  } else {
    doc_e=doc->cur_entry;
    do doc_e=doc_e->last;
    while (doc_e!=doc && doc_e->type_u8!=DOCT_NEW_LINE &&
	  doc_e->type_u8!=DOCT_PMT);
    if (doc_e!=doc && doc_e->type_u8!=DOCT_PMT) {
      do doc_e=doc_e->last;
      while (doc_e!=doc && doc_e->type_u8!=DOCT_NEW_LINE &&
	    doc_e->type_u8!=DOCT_PMT);
    }
    doc_e=doc_e->next;
    res=DocScanLine(doc,doc_e,NULL);
  }
  DocUnlock(doc);
gs_done:
  "$$PT$$$$FG$$$$BG$$";
  return res;
}

U0 set_windowinfo(U8 *name=NULL,U8 *title=NULL)
{//Allows you to set Fs values:
 //Fs->task_name
 //Fs->task_title
  if (name) StrCpy(Fs->task_name,name);
  if (title) StrCpy(Fs->task_title,title);
}

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

I64 valid_files(U8 *mask="11111111",...) 
{//Validate argv list of drives, files & directories.
 //It uses a mask to determine, whether you want
 //to know, if it exists <1> or doesn't <0>.
 //
 //Usage: 
 //        valid_files("10",buffera,bufferb);
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

U64 hash_code_for(U8 *str)
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

U0 my_scanflags(U8 *_dst_flags,U8 *lst,U8 *src)
{ //Stripped down version, of ScanFlags. Only allows '-'flags.
  //For my case, maybe I didn't need to do all this.
  //Need to test, but should allow for TempleOS style flags.
  //
  //Example: CatPrint(buf,"-LE");
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

I64 map_value(I64 x,I64 in_min,I64 in_max,I64 out_min,I64 out_max)
{//Map one range to another range.
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

#define gb 1073741824
#define gt gb / 10
#define STD "ST_DAYS_OF_WEEK"
#define STM "ST_MONTHS"

U0 tree_top(U8 *name) { "$$TR,\"%s\"$$",name; "$$ID,2$$"; }
U0 tree_trunk() "$$ID,-2S$$";

//Faster than IsDir(); for my case use.
Bool is_dir(CDirEntry *what) return what->attr & RS_ATTR_DIR;

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
U0 ls(U8 *files_find_mask='*',Bool tree_mode=FALSE)
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

    "$$MA,T=\"Listing\",LM=\"PopUpCd;Dir;\n\"$$: %s\n",st;

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
          PutDirLink(entry->name,entry->full_name);
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
