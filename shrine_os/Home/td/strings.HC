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

/*strings.HC
  Description:
      String related functions.
*/
U8 *str_cat(U8 **str,Bool flush=TRUE,...)
{//Build a str, from strings stored in argv.
 //flush clears the buffer first.
  U64 i = 0;

  if (flush) *str = '\0';

  for (;i<argc;i++) {
    CatPrint(str,argv[i]);
  }

  return str;
}
U8 str_upper(U8 *str)
{//Convert a string to uppercase.
  return MStrUtil(str,SUF_TO_UPPER);
}
U8 str_lower(U8 *str)
{//Convert a string to lowercase. 
  return MStrUtil(str,SUF_TO_LOWER);
}
Bool str_cmp(U8 *stra, U8 *strb, Bool ignore_case=FALSE)
{//StrCmp replacement which returns TRUE & FALSE.
 //Saying !StrCmp() for TRUE, erks me ...
  Bool res=FALSE;

  if (ignore_case) {
    res=(!(StrICmp(stra,strb)));
  }
  else { 
    res=(!(StrCmp(stra,strb)));
  }

  return res;
}
Bool str_cmpEX(U8 *cmp_to,Bool ignore_case=FALSE, ...)
{//EXpanded version of str_cmp. It can compare a string,
 //to a list of strings.
 //
 //Example: if (!str_cmpEX(entry->name,,".","..")) { ... }
  if (!cmp_to || (argc < 1)) return FALSE;

  Bool res=FALSE;

  I64 i=0;
  for (;i<argc;i++) {
    if (res=str_cmp(cmp_to,argv[i],ignore_case))
      break;
  }

  return res;
}
U64 str_len(U8 *str) return StrLen(str);
U8 *str_NQ(U8 *str)
{//De-Quotify$CM-LE-RE$$SY,3$tm$SY,0$ a string.
  U8 *p=str;
  while (*str)
  {
    if (*str==34) *str=' ';
    str++;
  }
  str=p;

  return MStrUtil(str,SUF_REM_LEADING|SUF_REM_TRAILING);
}
U8 MyGetStr(I64 flags=0)
{//Altered GetStr() to return -1 on <shift><esc>
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
    }

    if (ch==CH_SHIFT_ESC) {
//      if (flags&GSF_SHIFT_ESC_EXIT) {
//	Exit;
//      }
      if (flags&GSF_SHIFT_ESC_EXIT) {
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
}