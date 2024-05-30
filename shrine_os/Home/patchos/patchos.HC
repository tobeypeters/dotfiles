public U0 HijackFunc(U8 *orig, U8 *new)
{// Replace a system function with a new function

    // Warning old function address is not saved and this overwrites it!
    // Assembly code of old function is patched to jump to new instead.
    // Only a reboot will restore the original function!
    PUSHFD
    CLI
    *orig=0xe9;
    *(orig+1)(U32*)=new-orig-5;
    POPFD
}

public U0 Cdr() Cd("/");

public U0 More(U8 *filename)
{//Output txt or graphic file to the command line,
 //one screen at a time.
  I64 size=0;

  U64 max_lines=Fs->win_bottom-Fs->win_top,
             cl=0,
              i=0;

  U8 *buffer;

  buffer=FileRead(filename,&size);

  DocClear; DocTop;

  for (;i<size; i++)
  {
    "%c",buffer[i];

    if (buffer[i]=='\n') cl++;

    if (cl == max_lines) {
      KeyAndCont; cl = 0;
    }
  }

//  "\n";

  Free(buffer);
}

#define FUf_NO_ATAPI_CHECK	99 //For IsDir & FileFind - Tobey Peters

public extern Bool FAT32FileFind(CDrv *dv,I64 cur_dir_clus,
	U8 *name,CDirEntry *_res,I64 fuf_flags=0)

public extern Bool RedSeaFileFind(CDrv *dv,I64 cur_dir_clus,U8 *name,
	CDirEntry *_res,I64 fuf_flags=0)

Bool isdir(U8 *dir_name)
{//Is a str a valid, existing Dir?
// Desc: Added validation code and restructed the code,
//       to prevent infinite loops and exceptions
  U8 *mask=MStrPrint("%s/*",dir_name);
  Bool res=FALSE;

  U64 len=StrLen(dir_name);
  if (!StrCmp(dir_name,"")) goto cleanup;
  if (!len) goto cleanup;
  if (len>=2) { 
   if (dir_name[1]==':') {
     if (!DrvIsWritable(dir_name[0])) goto cleanup;

     U64 drv=ToUpper(dir_name[0]);
     if (!('A'<=drv<='Z')) goto cleanup;
     if (!Let2Drv(drv,FALSE)) goto cleanup;
   }
  }

  Bool old_silent=Silent;
  CDirContext *dirc;
  if (dirc=DirContextNew(mask)) {
    DirContextDel(dirc);
    res=TRUE;
  }

  Silent(old_silent);
cleanup:
  Free(mask);
  return res;
}

Bool filefind(U8 *filename,CDirEntry *_de=NULL,I64 fuf_flags=0)
{//$LK,"FUF_JUST_DIRS",A="MN:FUF_JUST_DIRS"$, $LK,"FUF_JUST_FILES",A="MN:FUF_JUST_FILES"$, $LK,"FUF_Z_OR_NOT_Z",A="MN:FUF_Z_OR_NOT_Z"$, $LK,"FUF_SCAN_PARENTS",A="MN:FUF_SCAN_PARENTS"$
//If you pass _de, you must Free(_de->full_name);
// Desc: Added validation code and restructed the code,
//       to prevent infinite loops and exceptions
  Bool res=FALSE;
  U64 len=StrLen(filename);

  if (len==0) return res;

  if (filename[len-1]=='/') return res;
  if (filename[len-1]==':') return res;
  if (filename[len-1]=='~') return res;

  I64 i,j,cur_dir_clus;
  U8 *altname,*curname,*full_name=NULL;
  CDirEntry de;
  CDirContext *dirc;
  Bool old_silent;
  if (fuf_flags&~FUG_FILE_FIND)
    throw('FUF');
  if (!filename || *filename && filename[1]==':' && !Let2Drv(*filename,FALSE))
    return FALSE;
  altname=ToggleZorNotZ(filename);
  if (fuf_flags&FUF_Z_OR_NOT_Z)
    j=2;
  else
    j=1;
  for (i=0;i<j && !res;i++) {
    if (!i)
      curname=filename;
    else
      curname=altname;
    old_silent=Silent;
    if (!(dirc=DirContextNew(curname)))
      Silent(old_silent);
    else {
      Silent(old_silent);
      cur_dir_clus=Name2DirClus(dirc->dv,Fs->cur_dir);
      switch (dirc->dv->fs_type) {
	case FSt_REDSEA:
	  res=RedSeaFileFind(dirc->dv,cur_dir_clus,dirc->mask,
		&de,fuf_flags);
	  break;
	case FSt_FAT32:
	  res=FAT32FileFind(dirc->dv,cur_dir_clus,dirc->mask,
		&de,fuf_flags);
	  break;
	default:
	  PrintErr("File System Not Supported\n");
      }
      if (res && _de) {
	if (StrCmp(Fs->cur_dir,"/"))
	  full_name=MStrPrint("%C:%s/%s",
		Drv2Let(Fs->cur_dv),Fs->cur_dir,de.name);
	else
	  full_name=MStrPrint("%C:/%s",Drv2Let(Fs->cur_dv),de.name);
      }
      DirContextDel(dirc);
    }
  }
  for (i=0;i<j && !res && fuf_flags&FUF_SCAN_PARENTS;i++) {
    if (!i)
      curname=filename;
    else
      curname=altname;
    old_silent=Silent;
    if (!(dirc=DirContextNew(curname)))
      Silent(old_silent);
    else {
      Silent(old_silent);
      cur_dir_clus=Name2DirClus(dirc->dv,Fs->cur_dir);
      while (!res && StrCmp(Fs->cur_dir,"/")) {
	Cd("..");
	cur_dir_clus=Name2DirClus(dirc->dv,Fs->cur_dir);
	switch (dirc->dv->fs_type) {
	  case FSt_REDSEA:
	    res=RedSeaFileFind(dirc->dv,cur_dir_clus,
		  dirc->mask,&de,fuf_flags);
	    break;
	  case FSt_FAT32:
	    res=FAT32FileFind(dirc->dv,cur_dir_clus,
		  dirc->mask,&de,fuf_flags);
	    break;
	  default:
	    PrintErr("File System Not Supported\n");
	}
      }
      if (res && _de) {
	if (StrCmp(Fs->cur_dir,"/"))
	  full_name=MStrPrint("%C:%s/%s",
		Drv2Let(Fs->cur_dv),Fs->cur_dir,de.name);
	else
	  full_name=MStrPrint("%C:/%s",
		Drv2Let(Fs->cur_dv),de.name);
      }
      DirContextDel(dirc);
    }
  }
  if (_de) {
    if (res) {
      MemCpy(_de,&de,sizeof(CDirEntry));
      _de->full_name=full_name;
    } else
      MemSet(_de,0,sizeof(CDirEntry));
  }
  Free(altname);

  return res;
}
public Bool ed(U8 *link_st,I64 edf_dof_flags=0)
{//Invoke document editor.
  U8 *filename,*needle_str;
  I64 i,num;
  Bool cont,res=FALSE;
  CDoc *doc;

  switch (i=EdLinkCvt(link_st,&filename,&needle_str,&num,edf_dof_flags)) {
    case -1:
      break;
    case LK_DEF:
      doc=DocNew;
      doc->desc='DictDef';
      ACDDefsPut(doc,filename,num);
      goto ej_doc;
    case LK_HELP_INDEX:
      doc=DocNew;
      doc->desc='HelpIndx';
      DocHelpIdx(doc,filename);
ej_doc:
      if (!(edf_dof_flags&EDF_BAIL)) {
	DocEd(doc);
	DocDel(doc);
      }
      if (!(edf_dof_flags&EDF_WAS_WRITE))
	res=TRUE;
      break;
    default:
      if (IsRaw)
	res=EdLite(filename,num,edf_dof_flags);
      else {
	cont=TRUE;
	if (!(edf_dof_flags&EDF_BAIL) && !(LK_DOC<=i<=LK_DOC_LINE) &&
	      !FilesFindMatch(filename,FILEMASK_TXT) &&
	      !PopUpCancelOk(ST_WARN_ST "Not Text File\n\n"))
	  cont=FALSE;
	if (cont)
	  res=DocFileEd(i,filename,needle_str,&num,edf_dof_flags);
      }
  }
  Free(filename);
  Free(needle_str);
  return res;
}

public Bool doced(CDoc *doc,I64 dof_flags=0)
{//Live for user interaction. End on <ESC> or <SHIFT-ESC>.
  Fs->border_src=BDS_CONST;Fs->border_attr=WHITE<<4+LTCYAN;

  CDoc *old_put_doc	  =DocPut,
	*old_display_doc=DocDisplay,
	*old_border_doc =DocBorder,*bdoc;
  CDocEntry *doc_e;
  I64 old_attr=Fs->text_attr,
	old_top =Fs->win_top, old_bottom=Fs->win_bottom,
	old_left=Fs->win_left,old_right =Fs->win_right,
	old_title_src=Fs->title_src;
  Bool res,unlock;
  U8 *old_task_title;
  if (dof_flags&DOF_WIN_MAX)
    WinMax;

  unlock=DocLock(doc);
  doc->win_task=Fs;
  bdoc=DocNew;
  bdoc->flags|=DOCF_BORDER_DOC;
  DocPrint(bdoc,"$$CM+TY+LX+NC,0,-1$$");

  DocPrint(bdoc,"$$TX+RX+BD,\"Í-Í\"$$");
  DocPrint(bdoc,"$$BK,1$$$$TX+LX+BD,\"Í-Í\"$$$$BK,0$$");
//  DocPrint(bdoc,"$$TX+RX+BD,\"ÍßÍ\"$$");
//  DocPrint(bdoc,"$$BK,1$$$$TX+LX+BD,\"ÍßÍ\"$$$$BK,0$$");

  old_task_title=StrNew(Fs->task_title);
  if (Fs->title_src!=TTS_LOCKED_CONST) {
    Fs->title_src=TTS_ED_FILENAME;
    MemCpy(Fs->task_title,doc->filename.name,STR_LEN-1);
  }

  doc_e=DocPrint(bdoc,"$$DA-TRM-P+BD+RD+CX+IV,LEN=STR_LEN-1,"
	"A=\" %%s \"$$");
//  doc_e=DocPrint(bdoc,"$$DA-TRM-P+BD+RD+CX,LEN=STR_LEN-1,"
//	"A=\"¸ %%s Õ\"$$");

  doc_e->data=&Fs->task_title;
  DocDataFmt(bdoc,doc_e);

  if (doc->flags & DOCF_ALLOW_UNDO) {
    DocPrint(bdoc,"$$CM+BY+LX+NC,1,1$$");
    doc_e=DocPrint(bdoc,"$$DA+BD+RD-TRM,RT=U32,A=\"Undo:%%03d\"$$\n");
    doc_e->data=&doc->undo_cnt;
    DocDataFmt(bdoc,doc_e);
  }

  DocPrint(bdoc,"$$CM+BY+RX+NC,-31,1$$");
  doc_e=DocPrint(bdoc,"$$TX+BD+TC,\" \"$$");
  doc_e->user_data=doc;
  doc_e->tag_cb=&EdMoreCB;
  doc_e=DocPrint(bdoc,"$$TX+BD+TC,\" \"$$");
  doc_e->user_data=doc;
  doc_e->tag_cb=&EdDollarTypeCB;
  doc_e=DocPrint(bdoc,"$$TX+BD+TC,\" \"$$");
  doc_e->user_data=doc;
  doc_e->tag_cb=&EdFilterCB;
  doc_e=DocPrint(bdoc,"$$TX+BD+TC,\" \"$$");
  doc_e->user_data=doc;
  doc_e->tag_cb=&EdOverStrikeCB;
  doc_e=DocPrint(bdoc,"$$TX+BD+TC,\" \"$$");
  doc_e->user_data=doc;
  doc_e->tag_cb=&EdAutoSaveCB;
  doc_e=DocPrint(bdoc,"$$TX+BD+TC,\" \"$$");
  doc_e->user_data=doc;
  doc_e->tag_cb=&EdDollarCB;
  doc_e=DocPrint(bdoc,"$$DA+BD+RD-TRM,A=\"Line:%%04d \"$$");
  doc_e->data=&doc->line;
  DocDataFmt(bdoc,doc_e);
  doc_e=DocPrint(bdoc,"$$DA+BD+RD-TRM,A=\"Col:%%04d\"$$\n");
  doc_e->data=&doc->col;
  DocDataFmt(bdoc,doc_e);

  DocRecalc(bdoc);
  DocRecalc(doc);
  if (!(dof_flags&DOF_DONT_HOME))
    DocTop(doc);
  Fs->border_doc=bdoc;
  if (doc!=old_display_doc)
    doc->parent_doc=old_display_doc;
  Fs->put_doc=Fs->display_doc=doc;
  if (!(dof_flags&DOF_DONT_TEXT_ATTR))
    Fs->text_attr=DOC_ATTR_DFT_TEXT;
  if (!(dof_flags&DOF_DONT_SHOW)) {
    LBts(&Fs->display_flags,DISPLAYf_SHOW);
    WinZBufUpdate;
  }
  if (dof_flags&DOF_SIZE_MIN)
    doc->flags|=DOCF_SIZE_MIN;

  DocUnlock(doc);
  if (!(dof_flags&DOF_DONT_WINMGR_SYNC)) {
    Refresh(2,TRUE);
    if (doc->flags&DOCF_SIZE_MIN)
      Refresh(2,TRUE);
  }
  res=View;

  DocLock(doc);
  if (res) {
    doc_e=doc->head.next;
    while (doc_e!=doc) {
      if (doc_e->type_u8==DOCT_DATA || doc_e->type_u8==DOCT_CHECK_BOX)
	DocDataScan(doc,doc_e);
      doc_e=doc_e->next;
    }
  }
  if (unlock)
    DocUnlock(doc);
  Fs->border_doc =old_border_doc;
  Fs->display_doc=old_display_doc;
  Fs->put_doc	 =old_put_doc;
  Fs->text_attr  =old_attr;
  if (Fs->title_src!=TTS_LOCKED_CONST) {
    Fs->title_src  =old_title_src;
    StrCpy(Fs->task_title,old_task_title);
  }
  Free(old_task_title);
  DocDel(bdoc);
  if (dof_flags&DOF_SIZE_MIN) {
    WinHorz(old_left,old_right);
    WinVert(old_top,old_bottom);
  }
  return res;
}

public U0 docputkey(CDoc *doc,I64 ch=0,I64 sc=0)
{//$LK,"PutKey",A="MN:PutKey"$(ch,sc) at doc insert pt, cur_entry.
  I64 i,x,y;
  CDoc *m;
  CDocEntry *doc_ce;
  U8 *st,*st2;
  Bool unlock;


  if (!doc && !(doc=DocPut) || doc->doc_signature!=DOC_SIGNATURE_VAL)
    return;
  if (doc->user_put_key && (*doc->user_put_key)(doc,doc->user_put_data,ch,sc))
    return;
  unlock=DocLock(doc);
  if (!Bt(doldoc.clean_scan_codes,sc.u8[0]))
    doc->flags|=DOCF_UNDO_DIRTY;
  DocCaptureUndo(doc);
  if (Bt(char_bmp_printable,ch) && !(sc&(SCF_CTRL|SCF_ALT))) {
    if (sc&SCF_KEY_DESC) {
      st=Char2KeyName(ch,FALSE);
      KeyDescSet("Char/'%s'",st);
      Free(st);
    } else
      EdCharIns(ch,sc,doc);
  } else {
    doc_ce=doc->cur_entry;
    x=doc->x; y=doc->y;
    if (sc&SCF_ALT)
      switch (ch) {
	case CH_BACKSPACE: //<CTRL-H>
	  if (!(sc&(SCF_SHIFT|SCF_CTRL))) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Undo");
	    else
	      DocUndoRestore(doc);
	  }
	  break;
      }
    else
      switch (ch) {
	case 0:
	  switch (sc.u8[0]) {
	    case SC_CURSOR_DOWN:
	      if (!(sc&SCF_CTRL)) {
		if (sc&SCF_KEY_DESC) {
		  if (sc&SCF_SHIFT)
		    KeyDescSet("Edit/Cursor Down, Sel");
		  else
		    KeyDescSet("Edit/Cursor Down");
		} else
		  EdLineDown(doc,sc);
		break;
	      } else
		sc&=~SCF_CTRL;
//Fall Through to SC_END
	    case SC_END:
	      if (!(sc&SCF_CTRL)) {
		if (sc&SCF_KEY_DESC) {
		  if (sc&SCF_SHIFT)
		    KeyDescSet("Edit/GoTo Doc End, Sel");
		} else {
		    if (sc&SCF_SHIFT) {
		      while (doc_ce!=doc) {
		        BEqu(&doc_ce->type,DOCEt_SEL,sc&SCF_SHIFT);
		        doc_ce=doc->cur_entry=doc_ce->next;
		      }
		      doc->cur_col=doc_ce->min_col;
		      DocFormBwd(doc);
		    }
                    else {
                      sc = (SCF_CTRL | SC_CURSOR_RIGHT);
                      EdCursorRight(doc,sc);
                    }
		}
	      }

	      else {
	        while (doc_ce!=doc) {
	          BEqu(&doc_ce->type,DOCEt_SEL,sc&SCF_SHIFT);
	          doc_ce=doc->cur_entry=doc_ce->next;
	        }
	        doc->cur_col=doc_ce->min_col;
	        DocFormBwd(doc);
	      }
	      break;
	    case SC_CURSOR_UP:
	      if (!(sc&SCF_CTRL)) {
		if (sc&SCF_KEY_DESC) {
		  if (sc&SCF_SHIFT)
		    KeyDescSet("Edit/Cursor Up, Sel");
		  else
		    KeyDescSet("Edit/Cursor Up");
		} else
		  EdLineUp(doc,sc);
		break;
	      } else
		sc&=~SCF_CTRL;
//Fall Through to SC_HOME
	    case SC_HOME:
	      if (!(sc&SCF_CTRL)) {
		if (sc&SCF_KEY_DESC) {
		  if (sc&SCF_SHIFT)
		    KeyDescSet("Edit/GoTo Top of Doc, Sel");
		  else
		    KeyDescSet("Edit/GoTo Top of Doc");
		} else {
		  if (doc_ce==doc) doc_ce=doc_ce->last;
		  while (doc_ce!=doc) {
		    BEqu(&doc_ce->type,DOCEt_SEL,sc&SCF_SHIFT);
		    doc_ce=doc->cur_entry=doc_ce->last;
		  }
		  doc_ce=doc->cur_entry=doc->head.next;
		  doc->cur_col=doc_ce->min_col;
		  DocFormFwd(doc);
		}
	      }
	      break;
	    case SC_PAGE_DOWN:
	      if (!(sc&SCF_CTRL)) {
		if (sc&SCF_KEY_DESC) {
		  if (sc&SCF_SHIFT)
		    KeyDescSet("Edit/Page Down, Sel");
		  else
		    KeyDescSet("Edit/Page Down");
		} else {
		  i=doc_ce->y+doc->win_task->win_height-1;
		  if (doc_ce->type_u8==DOCT_HEX_ED)
		    i+=doc->cur_col/3/doc_ce->hex_ed_width;
		  while (doc_ce!=doc &&
			(doc_ce->type_u8!=DOCT_HEX_ED && doc_ce->y<i ||
			doc_ce->type_u8==DOCT_HEX_ED &&
			doc_ce->y+doc->cur_col/3/doc_ce->hex_ed_width<i)) {
		    EdLineDown(doc,sc);
//paranoid check for stuck on same node
		    if (doc->cur_entry==doc_ce && doc_ce->type_u8!=DOCT_HEX_ED)
		      break;
		    doc_ce=doc->cur_entry;
		  }
		}
	      }
	      break;
	    case SC_PAGE_UP:
	      if (!(sc&SCF_CTRL)) {
		if (sc&SCF_KEY_DESC) {
		  if (sc&SCF_SHIFT)
		    KeyDescSet("Edit/Page Up, Sel");
		  else
		    KeyDescSet("Edit/Page Up");
		}else {
		  i=doc_ce->y-(doc->win_task->win_height-1);
		  if (doc_ce->type_u8==DOCT_HEX_ED)
		    i+=doc->cur_col/3/doc_ce->hex_ed_width;
		  while (doc_ce->last!=doc &&
			(doc_ce->type_u8!=DOCT_HEX_ED && doc_ce->y>i ||
			doc_ce->type_u8==DOCT_HEX_ED &&
			doc_ce->y+doc->cur_col/3/doc_ce->hex_ed_width>i) &&
			doc_ce->y!=doc->head.next->y) {
		    EdLineUp(doc,sc);
//paranoid check for stuck on same node
		    if (doc->cur_entry==doc_ce && doc_ce->type_u8!=DOCT_HEX_ED)
		      break;
		    doc_ce=doc->cur_entry;
		  }
		}
	      }
	      break;
	    case SC_CURSOR_LEFT:
	      if (sc&SCF_KEY_DESC) {
		if (sc&SCF_CTRL)
		  KeyDescSet("Edit/GoTo Start of Line");
		else {
		  if (sc&SCF_SHIFT)
		    KeyDescSet("Edit/Cursor Left, Sel");
		  else
		    KeyDescSet("Edit/Cursor Left");
		}
	      } else
		EdCursorLeft(doc,sc);
	      break;
	    case SC_CURSOR_RIGHT:
	      if (sc&SCF_KEY_DESC) {
		if (sc&SCF_CTRL)
		  KeyDescSet("Edit/GoTo End of Line");
		else {
		  if (sc&SCF_SHIFT)
		    KeyDescSet("Edit/Cursor Right, Sel");
		  else
		    KeyDescSet("Edit/Cursor Right");
		}
	      } else
		EdCursorRight(doc,sc);
	      break;
	    case SC_DELETE:
	      if (!(sc&SCF_CTRL)) {
		if (sc&SCF_KEY_DESC) {
		  if (sc&SCF_SHIFT)
		    KeyDescSet("Edit/Cut To Clip");
		  else
		    KeyDescSet("Char/Delete");
		} else {
		  if (sc&SCF_SHIFT)
		    ClipCut(doc);
		  else
		    EdCharDel(doc);
		}
	      }
	      break;
	    case SC_INS:
	      if (sc&(SCF_SHIFT|SCF_CTRL)!=(SCF_SHIFT|SCF_CTRL)) {
		if (sc&SCF_KEY_DESC) {
		  if (sc&SCF_SHIFT)
		    KeyDescSet("Edit/Paste Clip");
		  else if (sc&SCF_CTRL)
		    KeyDescSet("Edit/Copy to Clip");
		  else
		    KeyDescSet("Edit/Toggle Overstrike");
		} else {
		  if (sc&SCF_SHIFT)
		    ClipPaste(doc);
		  else if (sc&SCF_CTRL)
		    ClipCopy(doc);
		  else
		    doc->flags^=DOCF_OVERSTRIKE;
		}
	      }
	      break;
	    case SC_F1...SC_F10:
	      if (sc&SCF_CTRL) {
		if (sc&SCF_KEY_DESC) {
		  if (sc&SCF_SHIFT)
		    KeyDescSet("Cmd/Src Code of Sym");
		  else
		    KeyDescSet("Edit/Autocomplete Sym");
		} else {
		  DocUnlock(doc);
		  if (AutoComplete(ON)) {
		    if (sc&SCF_SHIFT)
		      ACMan(sc.u8[0]-SC_F1+1,Fs);
		    else
		      ACFillIn(sc.u8[0]-SC_F1+1);
		  }
		  DocLock(doc);
		}
	      } else {
		switch (sc.u8[0]) {
		  case SC_F1:
		    if (sc&SCF_KEY_DESC) {
		      if (sc&SCF_SHIFT)
			KeyDescSet("Cmd/About");
		      else
			KeyDescSet("Cmd/Help");
		    } else {
		      if (sc&SCF_SHIFT)
			Ed("::/Doc/AboutTempleOS.DD.Z");
		      else
			Ed("::/Doc/HelpIndex.DD.Z");
		    }
		    break;
		  case SC_F2:
		    if (sc&SCF_KEY_DESC) {
		      if (sc&SCF_SHIFT)
			KeyDescSet("Edit/Play Macro");
		      else
			KeyDescSet("Edit/Macro");
		    } else {
		      DocUnlock(doc);
		      if (sc&SCF_SHIFT) {
			if (TaskValidate(sys_macro_task))
			  PostMsgWait(sys_macro_task,
				MSG_KEY_DOWN_UP,CH_SHIFT_ESC,0);
			SysMacroStripKey(&sys_macro_head,ch,sc);
			PlaySysMacro;
		      } else
			EdMacroUtil;
		      DocLock(doc);
		    }
		    break;
		  case SC_F3:
		    if (sc&SCF_KEY_DESC) {
		      if (sc&SCF_SHIFT)
			KeyDescSet("Edit/Find Last");
		      else
			KeyDescSet("Edit/Find Next");
		    }else {
		      doc->find_replace->scan_fwd=!(sc&SCF_SHIFT);
		      EdFindNext(doc);
		    }
		    break;
		  case SC_F4:
		    if (sc&SCF_KEY_DESC) {
		      if (sc&SCF_SHIFT)
			KeyDescSet("Cmd/Insert Directory Name");
		      else
			KeyDescSet("Cmd/Insert FileName");
		    } else {
		      DocUnlock(doc);
		      if (sc&SCF_SHIFT)
			st=PopUpPickDir;
		      else
			st=PopUpPickFile;
		      DocLock(doc);
		      if (st) {
			DocPrintPartial(doc,"%s",st);
			Free(st);
		      }
		    }
		    break;
		  case SC_F5:
		    if (sc&SCF_KEY_DESC) {
		      if (sc&SCF_SHIFT)
			KeyDescSet("Cmd/Adam Include");
		      else
			KeyDescSet("Cmd/Run (Execute)");
		    } else {
		      if (st2=DocEntryLink(doc,doc_ce)) {
			st=DocLinkFile(st2);
			Free(st2);
		      } else {
			DocWrite(doc);
			st=StrNew(doc->filename.name);
		      }
		      if (st2=DirFile(st,"Run","HC.Z")) {
			if (FileFind(st2)) {
			  Free(st);
			  st=st2;
			} else
			  Free(st2);
		      }
		      if (st) {
			if (sc&SCF_SHIFT)
			  AdamFile(st);
			else
			  PopUpFile(st);
			Free(st);
		      }
		    }
		    break;
		  case SC_F6:
		    if (sc&SCF_KEY_DESC) {
		      if (sc&SCF_SHIFT)
			KeyDescSet("Cmd/God Doodle");
		      else
			KeyDescSet("Cmd/God Song");
		    } else {
//$LK,"::/Adam/God/HSNotes.DD"$
		      if (sc&SCF_SHIFT) {
			DocUnlock(doc);
			GodDoodle;
			DocLock(doc);
		      } else
			GodSong;
		    }
		    break;
		  case SC_F7:
		    if (sc&SCF_KEY_DESC) {
		      if (sc&SCF_SHIFT)
			KeyDescSet("Cmd/God Passage");
		      else
			KeyDescSet("Cmd/God Word");
		    } else {
//$LK,"::/Adam/God/HSNotes.DD"$
		      FifoU8Flush(god.fifo);
		      GodBitsIns(GOD_GOOD_BITS,KbdMsEvtTime>>GOD_BAD_BITS);
		      if (sc&SCF_SHIFT)
			GodBiblePassage;
		      else
			GodWord;
		    }
		    break;
		}
	      }
	      break;
	  }
	  break;
	case CH_CTRLA:
	  if (!(sc&SCF_SHIFT)) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Save As");
	    else if (DocWrite(doc,TRUE)&&(st=FileNameAbs(doc->filename.name))) {
	      DirContextDel(doc->filename.dirc);
	      doc->filename.dirc=DirContextNew(st);
	      Free(st);
	    }
	  }
	  break;
	case CH_CTRLB:
	  if (!(sc&SCF_SHIFT)) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Cmd/Toggle Border");
	    else
	      WinBorder(Bt(&doc->win_task->display_flags,
		    DISPLAYf_NO_BORDER),doc->win_task);
	  }
	  break;
	case CH_CTRLC:
	  if (!(sc&SCF_SHIFT)) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Copy to Clip");
	    else
	      ClipCopy(doc);
	  }
	  break;
	case CH_CTRLD:
	  if (!(sc&SCF_SHIFT)) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Cmd/File Manager");
	    else {
	      DocUnlock(doc);
	      FileMgr;
	      DocLock(doc);
	    }
	  }
	  break;
	case CH_CTRLF:
	  if (sc&SCF_SHIFT) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Cmd/Search Files");
	    else
	      FindWiz;
	  } else {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Find & Replace");
	    else
	      EdFindReplace(doc);
	  }
	  break;
	case CH_CTRLG:
	  if (!(sc&SCF_SHIFT)) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/GoTo Line Num");
	    else
	      EdGoToLine(doc);
	  }
	  break;
	case CH_BACKSPACE: //<CTRL-H>
	  if (!(sc&SCF_SHIFT)) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Char/Back Space");
	    else {
	      DocCaptureUndo(doc);
	      doc_ce=doc->cur_entry;
	      if (doc->cur_col<=doc_ce->min_col) {
		doc_ce=doc->cur_entry=doc_ce->last;
		if (doc_ce!=doc && doc_ce->type_u8==DOCT_SOFT_NEW_LINE)
		  doc_ce=doc->cur_entry=doc_ce->last;
		if (doc_ce==doc || doc_ce->type_u8==DOCT_PMT) {
		  doc_ce=doc->cur_entry=doc_ce->next;
		  doc->cur_col=doc_ce->min_col;
		} else {
		  doc->cur_col=doc_ce->max_col;
		  if (doc->cur_col>doc_ce->min_col)
		    doc->cur_col--;
		  EdCharDel(doc);
		}
	      } else {
		doc->cur_col--;
		EdCharDel(doc);
	      }
	    }
	  }
	  break;
	case CH_CTRLI:
	  if (sc.u8[0]!=SC_TAB) {
	    if (sc&SCF_SHIFT) {
	      if (sc&SCF_KEY_DESC)
		KeyDescSet("Dol/Unindent 2");
	      else
		DocPrint(doc,"$$ID,-2$$");
	    } else {
	      if (sc&SCF_KEY_DESC)
		KeyDescSet("Dol/Indent 2");
	      else
		DocPrint(doc,"$$ID,2$$");
	    }
	  }
	  break;
	case '\n':
	  if (sc&SCF_KEY_DESC) {
	    if (sc&SCF_SHIFT)
	      KeyDescSet("Char/Return");
	    else
	      KeyDescSet("Char/Page Break");
	  } else
	    EdCharIns(ch,sc,doc);
	  break;
	case CH_CTRLK:
	  if (sc&SCF_SHIFT) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Dol/Blinking Text Off");
	    else
	      DocPrint(doc,"$$BK,0$$");
	  } else {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Dol/Blinking Text On");
	    else
	      DocPrint(doc,"$$BK,1$$");
	  }
	  break;
	case CH_CTRLL:
	  if (sc&SCF_SHIFT) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Cmd/Code Tools");
	    else {
	      DocUnlock(doc);
	      EdCodeTools(doc);
	      DocLock(doc);
	    }
	  } else {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Cmd/Insert Text Widgets Wizard");
	    else {
	      DocUnlock(doc);
	      EdInsWidgetWiz;
	      DocLock(doc);
	    }
	  }
	  break;
	case CH_CTRLM:
	  if (sc&SCF_SHIFT) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Cmd/Personal Notes");
	    else
	      Ed("~/PersonalNotes.DD.Z");
	  } else {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Cmd/Personal Menu");
	    else {
	      m=DocRead("~/PersonalMenu.DD.Z");
	      DocMenu(m);
	      DocDel(m);
	    }
	  }
	  break;
	case CH_CTRLO:
	  if (sc&SCF_SHIFT) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Collapse");
	    else
	      DocCollapse(TRUE,doc);
	  } else {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Uncollapse");
	    else
	      DocCollapse(FALSE,doc);
	  }
	  break;
	case CH_CTRLP:
	  if (doc->flags & (DOCF_SUPERSCRIPT_MODE | DOCF_SUBSCRIPT_MODE)) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Dol/Toggle Super or Sub script");
	    else {
	      DocPrint(doc,"$$SY,0$$");
	      doc->flags&=~(DOCF_SUPERSCRIPT_MODE | DOCF_SUBSCRIPT_MODE);
	    }
	  } else if (sc&SCF_SHIFT) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Dol/Toggle Subscript");
	    else {
	      DocPrint(doc,"$$SY,3$$");
	      doc->flags|=DOCF_SUBSCRIPT_MODE;
	    }
	  } else {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Dol/Toggle Superscript");
	    else {
	      DocPrint(doc,"$$SY,-3$$");
	      doc->flags|=DOCF_SUPERSCRIPT_MODE;
	    }
	  }
	  break;
	case CH_CTRLQ:
	  break;
	case CH_CTRLR:
	  if (!(sc&SCF_SHIFT)) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Cmd/Sprite Graphic Resource");
	    else
	      if (!(doc->flags&DOCF_FORM) &&
		    !(doc->flags&(DOCF_PLAIN_TEXT|DOCF_PLAIN_TEXT_TABS))) {
		DocUnlock(doc);
		if (doc_ce->type_u8==DOCT_SPRITE)
		  EdSpriteEd(doc);
		else
		  EdSpriteIns(doc);
		DocLock(doc);
	      }
	  }
	  break;
	case CH_CTRLS:
	  if (sc&SCF_SHIFT) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Toggle AutoSave");
	    else
	      LBtc(&doc->flags,DOCf_AUTO_SAVE);
	  } else {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Save");
	    else
	      DocWrite(doc);
	  }
	  break;
	case CH_CTRLT:
	  if (sc&SCF_SHIFT) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Single Entry Toggle Plain Text");
	    else if (!(doc->flags&DOCF_FORM))
	      DocEntryToggle(doc);
	  } else {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Toggle Plain Text Display");
	    else if (!(doc->flags&DOCF_FORM))
	      DocFlagsToggle(doc,DOCF_PLAIN_TEXT);
	  }
	  break;
	case CH_CTRLU:
	  if (sc&SCF_SHIFT) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Dol/Underline Off");
	    else
	      DocPrint(doc,"$$UL,0$$");
	  } else {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Dol/Underline On");
	    else
	      DocPrint(doc,"$$UL,1$$");
	  }
	  break;
	case CH_CTRLV:
	  if (!(sc&SCF_SHIFT)) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Paste Clip");
	    else
	      ClipPaste(doc);
	  }
	  break;
	case CH_CTRLW:
	  if (sc&SCF_SHIFT) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Dol/Word Wrap Off");
	    else
	      DocPrint(doc,"$$WW,0$$");
	  } else {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Dol/Word Wrap On");
	    else
	      DocPrint(doc,"$$WW,1$$");
	  }
	  break;
	case CH_CTRLX:
	  if (!(sc&SCF_SHIFT)) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Cut To Clip");
	    else
	      ClipCut(doc);
	  }
	  break;
	case CH_CTRLY:
	  if (!(sc&SCF_SHIFT)) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Edit/Delete Line");
	    else
	      EdLineDel(doc);
	  }
	  break;
	case CH_CTRLZ:
	  if (sc&SCF_SHIFT) {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Dol/Inverted Text Off");
	    else
	      DocPrint(doc,"$$IV,0$$");
	  } else {
	    if (sc&SCF_KEY_DESC)
	      KeyDescSet("Dol/Inverted Text On");
	    else
	      DocPrint(doc,"$$IV,1$$");
	  }
	  break;
	case '0'...'9':
	  if (sc&SCF_CTRL) {
	    if (sc&SCF_KEY_DESC) {
	      if (sc&SCF_SHIFT)
		KeyDescSet("Cmd/Word Definition");
	      else
		KeyDescSet("Edit/Autocomplete Word");
	    } else {
	      if (AutoComplete(ON)) {
		DocUnlock(doc);
		if (sc&SCF_SHIFT)
		  ACDDef(ch-'0',Fs);
		else
		  ACDFillin(ch-'0');
		DocLock(doc);
	      }
	    }
	  }
	  break;
	case '[':
	  if (sc&SCF_CTRL) {
	    if (sc&SCF_SHIFT) {
	      if (sc&SCF_KEY_DESC)
		KeyDescSet("Edit/GoTo matching brace");
	      else
		EdFindPaired(doc,'}','{',FALSE);
	    } else {
	      if (sc&SCF_KEY_DESC)
		KeyDescSet("Edit/GoTo matching bracket");
	      else
		EdFindPaired(doc,']','[',FALSE);
	    }
	  }
	  break;
	case ']':
	  if (sc&SCF_CTRL) {
	    if (sc&SCF_SHIFT) {
	      if (sc&SCF_KEY_DESC)
		KeyDescSet("Edit/GoTo matching brace");
	      else
		EdFindPaired(doc,'{','}',TRUE);
	    } else {
	      if (sc&SCF_KEY_DESC)
		KeyDescSet("Edit/GoTo matching bracket");
	      else
		EdFindPaired(doc,'[',']',TRUE);
	    }
	  }
	  break;
      }
  }
  if (unlock)
    DocUnlock(doc);
  if (!(doc->flags&DOCF_DONT_SWAP_OUT))
    Yield;
}

public CDoc *docbordernew(CDoc *pdoc)
{//Make new std border doc.
  CDocEntry *doc_e;
  CDoc *bdoc;

  bdoc=DocNew;
  bdoc->flags|=DOCF_BORDER_DOC;
  if (pdoc) {
    DocPrint(bdoc,"$$CM+H+BY+RX+NC,-7,1$$");
    doc_e=DocPrint(bdoc,"$$TX+H+BD+TC,\" \"$$");
    doc_e->user_data=pdoc;
    doc_e->tag_cb=&EdFilterCB;
    doc_e=DocPrint(bdoc,"$$TX+H+BD+TC,\" \"$$");
    doc_e->user_data=pdoc;
    doc_e->tag_cb=&EdOverStrikeCB;
    doc_e=DocPrint(bdoc,"$$TX+H+BD+TC,\" \"$$");
    doc_e->user_data=pdoc;
    doc_e->tag_cb=&EdDollarCB;
    DocPrint(bdoc,"$$CM+H+BY+RX+NC,-18,1$$");
    doc_e=DocPrint(bdoc,"$$TX+BD+TC,\" \"$$");
    doc_e->user_data=pdoc;
    doc_e->tag_cb=&EdMoreCB;
    doc_e=DocPrint(bdoc,"$$TX+H+BD+TC,\" \"$$");
    doc_e->user_data=pdoc;
    doc_e->tag_cb=&EdDollarTypeCB;
  }
/*  DocPrint(bdoc,"$$CM+H+TY+NC,0,-1$$");
  doc_e=DocPrint(bdoc,"$$DA+H-TRM-P+BD+RD+CX+IV,LEN=STR_LEN-1,"
	"A=\" %%s \"$$");

//  doc_e->data=&Fs->task_title;
  doc_e->data=Fs->task_name;
  DocDataFmt(bdoc,doc_e);
  DocPrint(bdoc,"$$CM+H+NC,1,0$$$$TX+H+BD+IV,\"%X\"$$",Fs);*/

  DocPrint(bdoc,"$$TX+H+RX+BD,\"-\"$$");
  DocPrint(bdoc,"$$BK,1$$$$TX+H+LX+BD,\"-\"$$$$BK,0$$");

  return bdoc;
}
public U0 doctermnew()
{//Make into term win task with Put/Display/Border docs.
  CDoc *pdoc=DocNew;
  pdoc->right_click_link=&TermRightClickLink;
  pdoc->max_entries=4096;
  Fs->border_src=BDS_CUR_DRV;
  pdoc->desc='';

  Fs->put_doc=Fs->display_doc=pdoc;
  Fs->border_doc=DocBorderNew(pdoc);
  Fs->cur_menu=MenuFile("::/Doc/EdPullDown.DD");
  WinScrollsInit(Fs);
  Raw(OFF);
}

U8 *strnew(U8 *buf=NULL,CTask *mem_task=NULL,...)
{//Accepts a $LK,"CTask",A="MN:CTask"$ or $LK,"CHeapCtrl",A="MN:CHeapCtrl"$.NULL allocs off current task's heap.
  U8 *res=0;
  I64 size=0;

  if (buf||mem_task) {
    if (buf) {
      size=StrLen(buf)+1;
      res=MAlloc(size,mem_task);
      MemCpy(res,buf,size);
      goto done;
    }
    res=MAlloc(1,mem_task);
    goto done;
  }

  if (argc) {
    U64 i=0;

    while(i<argc) {
      size+=StrLen(argv[i]);

      i++;
    }

    if (size) size+=1;

    res=CAlloc(sizeof(U8)*size);
    for (i=0;i<argc;i++) {
      CatPrint(res,argv[i]);
    }
  }

done:
  return res;
}

HijackFunc(&IsDir,&isdir);
HijackFunc(&FileFind,&filefind);
HijackFunc(&DocEd,&doced);
HijackFunc(&DocPutKey,&docputkey);
HijackFunc(&DocBorderNew,&docbordernew);
HijackFunc(&DocTermNew,&doctermnew);
HijackFunc(&Ed,&ed);
