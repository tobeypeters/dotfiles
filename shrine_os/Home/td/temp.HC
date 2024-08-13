U8 *GetStrTest(U8 *msg=NULL,U8 *dft=NULL,I64 flags=0)
{
  CDoc *doc;
  CDocEntry *doc_e,*doc_e_end;
  U8 *st,*st2,*res;
  I64 ch,sc;

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

// Origninal start
//	Exit;
// Original end
// New Start
   res=StrNew("é");
   goto gs_done;
// New end


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
  return res;

}

U0 f_it() F("StrNew");

U0 f_me() {
  U8 *input=NULL;

  while (TRUE)
  {
    DocBottom;
    "\n>: ";
//    input=GetStr(,,GSF_SHIFT_ESC_EXIT);
    input=GetStrTest(,,GSF_SHIFT_ESC_EXIT);


"input: %s",input;

    if (*input=='é') { "Exit time\n"; break; }

    f_it;
  }

  Free(input);
}

SettingsPush;

f_me;

SettingsPop;
