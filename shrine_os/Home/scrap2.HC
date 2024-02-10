#define gigabyte 1073741824
#define gigatenth gigabyte / 10
#define STD "ST_DAYS_OF_WEEK"
#define STM "ST_MONTHS"

U0 ls_entry_info(CDirEntry *entry=NULL)
{
  if (!entry) return;

  CDateStruct ds, dsc;
  Date2Struct(&dsc,Now+local_time_offset);

  U64 gt = gigatenth,
       g = gigabyte;

  I64 fc = 0,
      dc = 0,
      bc = 0;

  Bool id = entry->attr & RS_ATTR_DIR;


  Date2Struct(&ds,entry->datetime+local_time_offset);


  "%c ",100-(!id*55);

  if (id) "%9s","";
  else
  {
    if (entry->size >= gigabyte)
      "%9d.%dg",entry->size/g,
                 (entry->size-((entry->size/g)*g))/gt;
    else "%9d",entry->size;
  }

  " %03tZ %02d ",ds.mon-1,STM,ds.day_of_mon;

  if (ds.year<dsc.year) "%5d",ds.year;
  else "%02d:%02d",ds.hour,ds.min;

  " ";
}

/*U0 ls_dir_sub(CDoc *doc,CDirEntry *tmpde)
{
  while (tmpde) 
  {

    if (tmpde->attr & RS_ATTR_DIR)
    {
      if (!str_cmpEX(tmpde->name,,".",".."))
      {
        DocPrint(doc,"$$TR,\"\"$$");
        DocPrint(doc,"$$MA,T=\"%s\",LM=\"Cd(\\\"%s\\\");Dir;\n\"$$",
                 tmpde->name,tmpde->full_name);

        if (tmpde->sub)
        {
          DocPrint(doc,"$$ID,+2$$");
          ls_dir_sub(doc,tmpde->sub);
          DocPrint(doc,"$$ID,-2$$");
        }
      }
    }

    DocPrint(doc,"$$LK,\"%s\",A=\"FI:%s\"$$\n",
             tmpde->name,tmpde->full_name);

    tmpde=tmpde->next;
  }

  DirTreeDel(tmpde);

  return;
}
*/
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

//      "Listing: $$MA,T=\"%s\",LM=\"MiniFM;\n\"$$\n",st;
//      "$$MA,T=\"Directory\",LM=\"PopUpCd;Dir;\n\"$$of%s\n",st;

    "$$MA,T=\"Listing\",LM=\"PopUpCd;Dir;\n\"$$: %s\n",st;

/*    CDateStruct ds, dsc;
    Date2Struct(&dsc,Now+local_time_offset);

    U64 gt = gigatenth,
         g = gigabyte;
*/
    I64 fc = 0,
        dc = 0,
        bc = 0;

    Bool id = FALSE;
             
    while (tmpde1)
    {
      tmpde2=tmpde1->next;

//      Date2Struct(&ds,tmpde1->datetime+local_time_offset);

      id = tmpde1->attr & RS_ATTR_DIR;

/*      "%c ",100-(!id*55);

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
*/
        ls_entry_info(tmpde1);
        if (id)
        {
          PutDirLink(tmpde1->name,tmpde1->full_name);

          dc+=1;

/*          if (!str_cmpEX(tmpde1->name,,".",".."))
          {
            "$$TR-C,\"\"$$";
            "$$ID,+2$$";
            ls_dir_sub(DocPut,FilesFind(tmpde1->full_name));
            "$$ID,-2S$$";
          }
*/        }
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
    "%11d File(s) %10d byte(s)\n%11d Dir(s)\n",fc,bc,dc;
  }
  else "No matching entries\n";

  Free(st);

//  }

}
