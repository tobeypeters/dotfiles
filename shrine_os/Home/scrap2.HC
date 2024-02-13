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
  if (!cmp_to || (argc < 1)) return FALSE;


  Bool result = FALSE;

  I64 i = 0;
  for (;i<argc;i++) {
    result = str_cmp(cmp_to,argv[i],ignore_case);

    if (result) break;
  }


  return result;
}

#define gb 1073741824
#define gt gb / 10
#define STD "ST_DAYS_OF_WEEK"
#define STM "ST_MONTHS"

Bool lsp = FALSE;

Bool is_dir(CDirEntry *what)
{//This is faster,then IsDir(), for my case.
  return what->attr & RS_ATTR_DIR;
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
//  " "; if (entry->sub) " ";
  //if (pdl) PutDirLink(entry->name,entry->full_name);
  if (!id) PutFileLink(entry->name,entry->full_name);

  return;
}
U0 ls_dir_sub(CDirEntry *entry)
{
  CDirEntry *temp = entry;

  "\n";

  while (entry)
  {
    if (!str_cmpEX(entry->name,,".",".."))
    {
      "\n";
      ls_entry_info(entry);
      if (is_dir(entry))
      {
        
        "$$TR,\"%s\"$$",entry->name;
        "$$ID,2$$";
        ls_dir_sub(FilesFind(entry->full_name,FUF_RECURSE));
        "$$ID,-2S$$";
      }
    }
    entry=entry->next;
  }
  entry=temp;

  "\n";

  DirTreeDel(entry);

  return;
}
U0 ls2(U8 *files_find_mask='*')
{//Linux'ish style directory listing.
  U8 *st;

  if (!(st=DirCur))
  {
    PrintErr("Invalid Drive\n");
    return;
  }

  CDirEntry *entry=FilesFind(files_find_mask),
            *start = NULL;

  if (entry)
  {
    st=MAllocIdent(entry->full_name);
    StrLastRem(st,"/");

    if (!st[2]) StrCpy(st+2,"/");

    "$$MA,T=\"Listing\",LM=\"PopUpCd;Dir;\n\"$$: %s\n",st;

    I64 fc = 0,
        dc = 0,
        bc = 0;

    Bool id = FALSE;

    start = entry;

    while (entry)
    {
      id = is_dir(entry);

      ls_entry_info(entry);

      if (id)
      {
        dc+=1;

        if (!str_cmpEX(entry->name,,".",".."))
        {
          "$$TR,\"%s\"$$",entry->name;
          "$$ID,2$$";
          ls_dir_sub(FilesFind(entry->full_name));
          "$$ID,-2S$$";
        }
        else "%s",entry->name;
      }
      else
      {
        fc+=1; bc+=entry->size;
      }

      "\n";

      entry = entry->next;
    }
    entry = start;

    "%11d File(s) %10d byte(s)\n%11d Dir(s)\n\n",fc,bc,dc;

    DirTreeDel(entry);

  }
  else "No matching entries\n";

  Free(st);
}
ls2;