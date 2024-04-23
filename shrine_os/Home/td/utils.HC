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

/*utils.HC
  Description:
      Miscellaneous functions.
*/
Bool I64_between(I64 val, I64 min,I64 max) return (min<=val<=max);

U0 set_windowinfo(U8 *name=NULL,U8 *title=NULL)
{//Allows you to set Fs values:
 //Fs->task_name
 //Fs->task_title
  if (name) StrCpy(Fs->task_name,name);
  if (title) StrCpy(Fs->task_title,title);
  return;
}
Bool I64_IN(I64 inval,...)
{//Check to see if an I64 is in a given argv list.
  U64 i=0;

  for (;i<argc;i++) {
    if (inval==argv[i]) {
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
U8 arg_str(U8 **args,U64 cnt)
{//Build a comma seperated str, from a list of arguments.
 //Automatically adds quotes around them.
 //Prefacing an argument with NQ, will keep the next argument 
 //from being quoted.
  U64 i=0,
      s=cnt;

  for(;i<cnt;i++)
    s+=str_len(args[i]);

  U8 *buf=CAlloc(sizeof(U8)*s+10);

  Bool nq=FALSE;
  for(i=0;i<cnt;i++)
  {
    if (str_cmp(args[i],"NQ")) { nq=TRUE; goto continue; }
    if (args[i][0]!=34&&!nq)
      str_cat(buf,FALSE,"\"",args[i],"\"");
    else { str_cat(buf,FALSE,args[i]); nq=FALSE; }
    if (i<cnt-1) str_cat(buf,FALSE,",");
    continue:
  }

  return buf;
}
#include "C:/Home/td/debug"
U0 shell_exec(U8 *cmd,Bool noparse=FALSE,...)
{//Execute a templeOS shell command.
  /*Examples:
  Generate: Copy("b.HC","temp");
  shell_exec("Copy",,"b.HC","temp");

  Generate: Touch("filename.HC","");
  shell_exec("Touch",,"filename.HC","\"\"");

  Generate: MStrUtil("upperme",SUF_TO_UPPER);
  shell_exec("MStrUtil",,"\"upperme\"","NQ","SUF_TO_UPPER"); */
  if (!argc) return;

  U8 *as;

//  "\n";
  if (noparse) { ExePutS(argv[0]); goto done; }

  if (argc) as=arg_str(argv,argc);
  else as=StrNew("");

  U8 *buf=CAlloc(sizeof(U8)*(str_len(cmd)+str_len(as)+3));

  str_cat(buf,FALSE,cmd,"(",as,");");

  debug_prn(buf);
  
//  ExePutS(buf);
  Free(as);
  Free(buf);
  done:
//    "\n";
    return;
}
U0 viewer(U8 *cmd)
{//Execute a specified command and examine the results
 //in "view" mode.
  DocClear; DocTop;
  ExePutS(cmd);
  "$$BK,1$$Press ESC to exit ...$$BK,0$$";
  DocTop;View; DocBottom;
  PutChars(CH_CTRLY);
  return;
}
I64 map_value(I64 x,I64 in_min,I64 in_max,I64 out_min,I64 out_max)
{//Map one range to another range.
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
U0 zFree(U8 *cube,Bool free=TRUE)
{//Zero out mem and free it.
  MemSet(cube,'\0',sizeof(cube));
  if (free) Free(cube);
  return;
}

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
