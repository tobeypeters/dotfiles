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


  Date2Struct(&ds,tmpde1->datetime+local_time_offset);


  "%c ",100-(!id*55);

  if (id)
  {
    "%9s","";
    goto dir;
  }
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

  if (id)
  {
    PutDirLink(entry->name,entry->full_name);

    dc+=1;

    if (!str_cmpEX(entry->name,,".",".."))
    {
      "$$TR-C,\"\"$$";
      "$$ID,+2$$";
//      TreeSub(DocPut,FilesFind(entry->full_name));
      "$$ID,-2S$$";
    }
  }
  else
  {
    PutFileLink(entry->name,entry->full_name);
    fc+=1;
    bc+=entry->size;
  }

  "\n";

  "%11d File(s) %10d byte(s)\n%11d Dir(s)\n",fc,bc,dc;
}
