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

U0 ls_entry_info(CDirEntry *entry=NULL)
{
  if (!entry) return;

  CDateStruct ds, dsc;
  Date2Struct(&dsc,Now+local_time_offset);

  Bool id = entry->attr & RS_ATTR_DIR;

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
  if (id) PutDirLink(entry->name,entry->full_name);
  else  PutFileLink(entry->name,entry->full_name);

//  "\n";
}
U0 ls_dir_sub(CDoc *doc,CDirEntry *entry)
{
  "\n";
  while (entry) 
  {
    "\n";

    ls_entry_info(entry);
    if (entry->attr & RS_ATTR_DIR)
    {
      if (!str_cmpEX(entry->name,,".",".."))
      {
        if (entry->sub)
        {
          DocPrint(doc,"$$ID,+2$$");
          entry->next;
          ls_dir_sub(doc,entry->sub);
          DocPrint(doc,"$$ID,-2$$");
        }
      }
    }
    entry=entry->next;
  }
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

  CDirEntry *tmpde1=NULL,*tmpde2;
  tmpde1=FilesFind(files_find_mask);


  if (tmpde1) 
  {
    st=MAllocIdent(tmpde1->full_name);
    StrLastRem(st,"/");

    if (!st[2]) StrCpy(st+2,"/");

    "$$MA,T=\"Listing\",LM=\"PopUpCd;Dir;\n\"$$: %s\n",st;

    I64 fc = 0,
        dc = 0,
        bc = 0;

    Bool id = FALSE;
             
    while (tmpde1)
    {
      tmpde2=tmpde1->next;

      id = tmpde1->attr & RS_ATTR_DIR;

      ls_entry_info(tmpde1);

      if (id)
      {
        dc+=1;

        if (!str_cmpEX(tmpde1->name,,".",".."))
        {
          "$$TR,\"\"$$";
          "$$ID,2$$";
          ls_dir_sub(DocPut,FilesFind(tmpde1->full_name));
          "$$ID,-2S$$";
        }
      }
      else
      {
        fc+=1; bc+=tmpde1->size;
      }

      "\n";

      DirEntryDel(tmpde1);

      tmpde1=tmpde2;
    }
    "%11d File(s) %10d byte(s)\n%11d Dir(s)\n",fc,bc,dc;
  }
  else "No matching entries\n";

  Free(st);
}
ls2;