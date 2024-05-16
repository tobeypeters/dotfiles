Cdr;
CDirEntry *de=FilesFind("/scrap.HC",FUF_RECURSE);



U0 gato(CDirEntry *entry)
{
  CDirEntry *temp=entry;

  while (entry)
  {
    "%s\n",entry->full_name;
    if (entry->sub)
    {
      gato(FilesFind(entry->full_name,FUF_RECURSE));
    }
    entry=entry->next;
  }

  entry=temp;

  DirTreeDel(entry);

  return;
}

gato(de);