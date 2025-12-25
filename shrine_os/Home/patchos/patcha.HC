/*patcha.HC
  Description:
      Modified TempleOS functions - Created by Terry Davis.  99.9% of
      the code was HIS.

  The HijackFunc() code is taken from TinkerOS, which is a very enhanced
  branch of TempleOS.

  TinkerOS and the Original source can be found at:

  http://www.github.com/tinkeros/TinkerOS

  Sstem files modded:

   * FileMgr: $LK,"Mouse support removed",A="FF:/Adam/ABlkDev/FileMgr.HC.Z,mouse_removed"$
*/

#include "~/patchos/patchb"

public U0 SwapFuncs(U8 *funca,U8 *funcb,CHashTable *ht=adam_task->hash_table)
{//Swap the addresses of two functions
  CHash* result=HashFind(funca,ht,HTT_FUN);

  if (result && (result->type & HTT_FUN)!=0)
    result(CHashFun *)->exe_addr=funcb;
  else
    Adam("\"\n\n$$LTCYAN$$:SwapFuncs error:$$FG$$ ...\n\n\";");
}

#help_index "Hash"
#help_file "::/Doc/Hash"
public U0 WipeFunc(U8 *func,CHashTable *ht=adam_task->hash_table)
{//Remove a function from adam's hash_table.
  CHash* result=HashFind(func,ht,HTT_FUN);

  if (result && (result->type & HTT_FUN)!=0)
    HashRemDel(result,ht);
}
#help_index ""

WipeFunc("Del");
WipeFunc("DocBorderNew");
WipeFunc("DocTermNew");
WipeFunc("FileFind");
WipeFunc("IsDir");
WipeFunc("Move");
WipeFunc("Copy");

public class CCtrl
{//Extended Control class.
  CCtrl *next,*last;
  CTask *win_task;
  I64	type,flags;

  //win pix coordinates
  I64	left,right,top,bottom;

  //scrn pix coordinates (derived)
  I64	scrn_left,scrn_right,scrn_top,scrn_bottom;

  U8	*state;

  //called on resize
  U0	(*update_derived_vals)(CCtrl *c);
  U0	(*draw_it)(CDC *dc,CCtrl *c);

  Bool	(*inside_ctrl)(CCtrl *c,I64 x,I64 y); //For nonbox shapes
  U0	(*left_click)(CCtrl *c,I64 x,I64 y,Bool down);
  U0	(*right_click)(CCtrl *c,I64 x,I64 y,Bool down);
  U0	(*wheel_chg)(CCtrl *c,I64 delta);
  U8	*name;
  U8	*label;
  U64	light_border,dark_border,bg,fg;
  Bool	down;
};


public extern I64 FAT32FilesDel(CDrv *dv,U8 *cur_dir,U8 *files_find_mask,I64 fuf_flags,
		     Bool del_dir,Bool print_msg)

public extern I64 RedSeaFilesDel(CDrv *dv,U8 *cur_dir,U8 *files_find_mask,I64 fuf_flags,
		     Bool del_dir,Bool print_msg)

public extern Bool FAT32FileFind(CDrv *dv,I64 cur_dir_clus,
	U8 *name,CDirEntry *_res,I64 fuf_flags=0)

public extern Bool RedSeaFileFind(CDrv *dv,I64 cur_dir_clus,U8 *name,
	CDirEntry *_res,I64 fuf_flags=0)

public Bool IsDir(U8 *dir_name)
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
public Bool Copy(U8 *src_files_find_mask,U8 *dst_files_find_mask=".")
{//Copy files.
//If the name ends in ".Z", it will
  //be stored compressed.  If not ".Z"
  //it will be stored uncompressed.

  if (!StrLen(src_files_find_mask)) return FALSE;

  Bool res=TRUE;
  CDirContext *dirc;
  CDirEntry *tmpde,*tmpde1;
  U8 *st;
  if (!(tmpde1=FilesFind(src_files_find_mask,FUF_CLUS_ORDER)))
    return FALSE;
  if (IsDir(dst_files_find_mask)) {
    if (dirc=DirContextNew(dst_files_find_mask,TRUE)) {
      tmpde=tmpde1;
      while (tmpde) {
	if (!(tmpde->attr & RS_ATTR_DIR)) {
	  st=FileNameAbs(tmpde->name);
	  if (!CopySingle(tmpde->full_name,st))
	    res=FALSE;
	  Free(st);
	}
	tmpde=tmpde->next;
      }
      DirContextDel(dirc);
    }
    DirTreeDel(tmpde1);
    return res;
  } else {
    DirTreeDel(tmpde1);
    return CopySingle(src_files_find_mask,dst_files_find_mask);
  }
}
public I64 Del(U8 *files_find_mask,Bool make_mask=FALSE,
Bool del_dir=FALSE,Bool print_msg=TRUE)
{//Delete files or move files, to the "trash can".
 //To move them to the trash can, set make_mask to TRASH
 //Examples:
 //           Del("filea.HC",TRASH);
 //           Del("*",TRASH); //Deletes all files in a given directory.
 //           Del("filea.HC",TRASH+TRUE); //Allow make_mask to used as before.
  if (make_mask>=TRASH)
  {
    dump_exists;

    if (FilesFind(files_find_mask))
      Copy(files_find_mask,TRASH_DIR);

    make_mask-=TRASH; //Sets make_mask to TRUE or FALSE
  }

  I64 res=0;
  CDirContext *dirc;
  if (dirc=DirContextNew(files_find_mask,make_mask)) {
    switch (dirc->dv->fs_type) {
      case FSt_REDSEA:
	res=RedSeaFilesDel(dirc->dv,Fs->cur_dir,dirc->mask,
	      0,del_dir,print_msg);
	break;
      case FSt_FAT32:
	res=FAT32FilesDel(dirc->dv,Fs->cur_dir,dirc->mask,
	      0,del_dir,print_msg);
	break;
      default:
	PrintErr("File System Not Supported\n");
    }
    DirContextDel(dirc);
  }
  return res;
}
public Bool Move(U8 *f1,U8 *f2)
{//Move files from one location to another or rename.
  if (!*f1||!*f2) return FALSE;

  dump_exists;

  if (Copy(f1,f2)) {
    Del(f1);
    return TRUE;
  }
  return FALSE;
}
public Bool FileFind(U8 *filename,CDirEntry *_de=NULL,I64 fuf_flags=0)
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
public Bool doced(CDoc *doc,I64 dof_flags=0)
{//Live for user interaction. End on <ESC> or <SHIFT-ESC>.
  Fs->border_src=BDS_CONST;Fs->border_attr=BLACK<<4+WHITE; ///sponge

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
//DocPutKey changes should really just be put,
//in ~/HomeKeyPlugIns.HC.
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
public CDoc *DocBorderNew(CDoc *pdoc)
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
public U0 DocTermNew()
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
public Bool DocEntryRan=FALSE;
public I64 docentryrun(CDoc *doc,CDocEntry *doc_e,
	Bool exited,I64 *_has_action=NULL)
{//Do action on final entry sel by user.
//Sometimes returns locked, sometimes unlocked
  DocEntryRan=TRUE;

  U8 ch=doc->cmd_U8,*st;
  I64 res=DOCM_CANCEL,has_action=FALSE;
  CHashDefineStr *tmph;
  DocLock(doc);
  if (!exited) {
    if (doc_e->de_flags & DOCEF_ESC) {
      Msg(MSG_KEY_DOWN,CH_ESC,0,1<<JOBf_DONT_FILTER);
      has_action=TRUE;
      goto er_done;
    } if (doc_e->de_flags & DOCEF_QUIT) {
      Msg(MSG_KEY_DOWN,CH_SHIFT_ESC,0,1<<JOBf_DONT_FILTER);
      has_action=TRUE;
      goto er_done;
    } else if (doc_e->de_flags & DOCEF_CHECK_COLLAPSABLE) {
      doc_e->de_flags^=DOCEF_CHECKED_COLLAPSED;
      has_action=TRUE;
    }
  }
  try {
    if (ch==CH_SPACE) {
      if (doc_e->de_flags & DOCEF_LINK && doc->left_click_link) {
	res=(*doc->left_click_link)(doc,doc_e);
	has_action=TRUE;
      }
      if (doc_e->de_flags & DOCEF_LEFT_EXP) {
	res=doc_e->left_exp;
	has_action=TRUE;
	Msg(MSG_CMD,res,0,1<<JOBf_DONT_FILTER);
      }
      if (doc_e->de_flags & DOCEF_LEFT_CB && doc_e->left_cb) {
	DocUnlock(doc);
	res=(*doc_e->left_cb)(doc,doc_e);
	has_action=TRUE;
	Msg(MSG_CMD,res,0,1<<JOBf_DONT_FILTER);
      }
      if (doc_e->de_flags & DOCEF_LEFT_MACRO) {
	if (doc_e->de_flags & DOCEF_POPUP) {
	  st=StrNew(doc_e->left_macro);
	  DocUnlock(doc);
	  PopUp(st,Fs);
	  Free(st);
	} else {
	  if (doc_e->de_flags & DOCEF_LEFT_IN_STR)
	    InStr("%s",doc_e->left_macro);
	  else
	    In("%s",doc_e->left_macro);
	}
	has_action=TRUE;
      }
      if (!exited && doc_e->de_flags & DOCEF_LST &&
	    doc_e->de_flags & DOCEF_DEFINE &&
	    (tmph=HashFind(doc_e->define_str,
	    doc->win_task->hash_table,HTT_DEFINE_STR)) &&
	    (res=PopUpPickLst(tmph->data))!=DOCM_CANCEL) {
	DocDataFmt(doc,doc_e,res);
	DocDataScan(doc,doc_e);
	has_action=TRUE;
      }
    } else if (ch=='\n') {
      if (doc_e->de_flags & DOCEF_LINK && doc->right_click_link) {
	res=(*doc->right_click_link)(doc,doc_e);
	has_action=TRUE;
      }
      if (doc_e->de_flags & DOCEF_RIGHT_EXP) {
	res=doc_e->right_exp;
	has_action=TRUE;
	Msg(MSG_CMD,res,0,1<<JOBf_DONT_FILTER);
      }
      if (doc_e->de_flags & DOCEF_RIGHT_CB && doc_e->right_cb) {
	DocUnlock(doc);
	res=(*doc_e->right_cb)(doc,doc_e);
	has_action=TRUE;
	Msg(MSG_CMD,res,0,1<<JOBf_DONT_FILTER);
      }
      if (doc_e->de_flags & DOCEF_RIGHT_MACRO) {
	if (doc_e->de_flags & DOCEF_POPUP) {
	  st=StrNew(doc_e->right_macro);
	  DocUnlock(doc);
	  PopUp(st,Fs);
	  Free(st);
	} else {
	  if (doc_e->de_flags & DOCEF_RIGHT_IN_STR)
	    InStr("%s",doc_e->right_macro);
	  else
	    In("%s",doc_e->right_macro);
	}
	has_action=TRUE;
      }
    }
  }
  catch
    DocBottom(doc);
  doc->cmd_U8=CH_SPACE;
er_done:
  if (_has_action) *_has_action=has_action;
  return res;
}
U8 drv_text_attr[3]={BLACK,BLUE,RED};

public U8 drvtextattrget(U8 drv_let=0)
//public U8 drvtextattrget(U8 drv_let=0)
{//Get color of drive.
  drv_let=Let2Let(drv_let);
  if ('A'<=drv_let<='Z')
    return drv_text_attr[drv_let%sizeof(drv_text_attr)]<<4|WHITE;
  else
    return BLACK<<4|WHITE;
}
public U0 ctrlaltt(I64)
{
  DocEntryRan=FALSE;
  User;
}

#help_index "File/Cmd Line (Typically);Cmd Line (Typically)"
#define FM_PICK_DIRFILE	   3
#define FM_PICK_DIRSTRICT  4
#define FM_PICK_FILESTRICT 5

public U8 *filemgr(I64 mode=FM_NORMAL,CTask *mem_task=NULL)
{//File manager. Also, used to choose files and dirs.
  CDirEntry *head=NULL,*tmpde,*tmpde1,*tmpde2;
  I64 sc,ch,arg1,arg2,msg_code;
  CDoc *doc=NULL,*old_put_doc=DocPut,*old_display_doc=DocDisplay;
  U8 *res=NULL,*st,*st2,*old_cur_dir=DirCur;
  CDocEntry *doc_ce=NULL,*doc_e;
  Bool okay;

  SettingsPush; //See $LK,"SettingsPush",A="MN:SettingsPush"$
  fp_old_final_scrn_update=gr.fp_final_scrn_update;
  MenuFilePush("::/Doc/FileMgrPullDown.DD");
  FMRebuildDoc(&doc,&head,mode);
  if (tmpde1=Cd2DirEntry(head,old_cur_dir))
    doc->cur_entry=tmpde1->user_data;
  while (tmpde1) {
    if (tmpde1->attr&RS_ATTR_DIR)
      tmpde1->user_data(CDocEntry *)->de_flags&=~DOCEF_CHECKED_COLLAPSED;
    tmpde1=tmpde1->parent;
  }
  do {
    DocUnlock(doc);
    do msg_code=GetMsg(&arg1,&arg2,
	    1<<MSG_KEY_DOWN|1<<MSG_MS_L_DOWN|1<<MSG_MS_L_UP|1<<MSG_MS_R_UP);
    while (Fs!=sys_focus_task);
    DocLock(doc);
    switch (msg_code) {
      case MSG_MS_R_UP:
	DocUnlock(doc);
	FMRightClick;
	DocLock(doc);
	break;
      case MSG_MS_L_DOWN:
	doc_ce=doc->cur_entry;
	fm_ms_str=doc_ce->tag;
	gr.fp_final_scrn_update=&FMFinalScrnUpdate;
	break;
      case MSG_MS_L_UP:
	if (doc_ce) {
	  gr.fp_final_scrn_update=fp_old_final_scrn_update;
	  if (WinCursorPosSet(Fs,arg1+Fs->pix_left+Fs->scroll_x,
		arg2+Fs->pix_top+Fs->scroll_y,TRUE)) {
	    doc_e=doc->cur_entry;
	    if (doc_e!=doc_ce) {
	      st2=NULL;
	      if (doc_e->type_u8==DOCT_MENU_VAL) {
		tmpde1=doc_e->user_data;
		if (tmpde1=tmpde1->parent)
		  st2=StrNew(tmpde1->full_name);
	      } else if (doc_e->type_u8==DOCT_TREE) {
		tmpde1=doc_e->user_data;
		st2=StrNew(tmpde1->full_name);
	      }
	      if (st2 && doc_ce->type_u8==DOCT_MENU_VAL) {
		tmpde=doc_ce->user_data;
		Silent;
		Move(tmpde->full_name,st2);
		Silent(OFF);
		FMRebuildDoc(&doc,&head,mode);
	      } else if (st2 && doc_ce->type_u8==DOCT_TREE) {
		tmpde=doc_ce->user_data;
		okay=TRUE;
		tmpde2=tmpde1;
		while (tmpde2) {
		  if (tmpde2!=tmpde)
		    tmpde2=tmpde2->parent;
		  else {
		    okay=FALSE;
		    break;
		  }
		}
		if (okay) {
		  if (*tmpde1->name)
		    st=MStrPrint("%s/%s",tmpde1->full_name,tmpde->name);
		  else
		    st=MStrPrint("%s%s",tmpde1->full_name,tmpde->name);
		  if (StrCmp(tmpde->full_name,st)) {
		    Silent;
		    CopyTree(tmpde->full_name,st);
		    DelTree(tmpde->full_name);
		    Silent(OFF);
		    FMRebuildDoc(&doc,&head,mode);
		  }
		  Free(st);
		}
	      }
	      Free(st2);
	      FlushMsgs;
	    } else
	      if (doc_e->type_u8==DOCT_MENU_VAL) {
		DocUnlock(doc);
		Ed(doc_e->user_data(CDirEntry *)->full_name);
		DocLock(doc);
	      }
	    doc_ce=NULL;
	  }
	}
	break;
      case MSG_KEY_DOWN:
	doc_ce=NULL;
	ch=arg1; sc=arg2;
	if (sc.u8[0]==SC_DELETE && !(sc&(SCF_SHIFT|SCF_CTRL)))
	  ch=CH_CTRLY;
	if (ch && sc&SCF_ALT) goto fm_regular_key;
	switch (ch) {
	  case '\n':
	    DocUnlock(doc);
	    FMRightClick;
	    DocLock(doc);
	    break;
	  start:
	    DocUnlock(doc);
	    case CH_CTRLV:
	      FMCopy(doc);
	      break;
	    case 'r':
	      FMRename(doc);
	      break;
	    case 'd':
	      FMMkDir(doc);
	      break;
	    case CH_CTRLY:
	      FMDelete(doc);
	      break;
	    case 'c':
	      FMChgDsk(doc);
	      break;
	    case 'i':
	      FMMountISO(doc);
	      break;
	    case 'u':
	      FMUnmount(doc);
	      break;
	    case 'm':
	      FMMakeISO(doc);
	      break;
	    case 'B':
	      FMBurnISO(doc);
	      break;
	    case 'f':
	      FMFmtDrv(doc);
	      break;
	  end:
	    FMRebuildDoc(&doc,&head,mode);
	    break;
	  case CH_SHIFT_ESC:
	    break;
	  case CH_SPACE:
	    if (doc->cur_entry->type_u8==DOCT_MENU_VAL) {
	      DocUnlock(doc);
	      Ed(doc->cur_entry->user_data(CDirEntry *)->full_name);
	      DocLock(doc);
	    } else
	      goto fm_regular_key;
	    break;
	  case CH_SHIFT_SPACE:
	    if (doc->cur_entry->type_u8==DOCT_MENU_VAL) {
	      DocUnlock(doc);
	      Plain(doc->cur_entry->user_data(CDirEntry *)->full_name);
	      DocLock(doc);
	    } else
	      goto fm_regular_key;
	    break;
	  case CH_ESC:
	    doc_ce=doc->cur_entry;
	    tmpde=doc_ce->user_data;

	    //ADD start
	    if (mode==FM_PICK_DIRFILE)
	    {
	      res=StrNew(tmpde->full_name,mem_task);

	      break;
	    }
	    if (mode==FM_PICK_FILESTRICT)
	    {
	      if (doc_ce->type_u8==DOCT_MENU_VAL)
		res=StrNew(tmpde->full_name,mem_task);
	      else
		res=StrNew("",mem_task);

	      break;
	    }
	    //ADD end
	    if (mode==FM_PICK_FILE && doc_ce->type_u8==DOCT_MENU_VAL)
	      res=StrNew(tmpde->full_name,mem_task);
	    else if (mode==FM_PICK_DIR||
                     mode==FM_PICK_DIRSTRICT) {

//DIR start
	      if (doc_ce->type_u8==DOCT_TREE)
		res=StrNew(tmpde->full_name,mem_task);
	      else if (doc_ce->type_u8==DOCT_MENU_VAL &&
		    (tmpde=tmpde->parent))
              {
                if (mode==FM_PICK_DIRSTRICT)
		  res=StrNew("",mem_task);
                else
		  res=StrNew(tmpde->full_name,mem_task);
              }
//DIR end

	    }
	    break;

	  default:
	    if (sc.u8[0]==SC_INS && sc&SCF_SHIFT && !(sc&SCF_CTRL)) {
	      FMCopy(doc);
	      FMRebuildDoc(&doc,&head,mode);
	    } else if (sc.u8[0]==SC_F5) {
	      if (doc->cur_entry->type_u8==DOCT_MENU_VAL) {
		tmpde=doc->cur_entry->user_data;
		DocUnlock(doc);
		if (sc&SCF_SHIFT)
		  AdamFile(tmpde->full_name);
		else
		  PopUpFile(tmpde->full_name);
		DocLock(doc);
	      }
	    } else {
fm_regular_key:
	      DocUnlock(doc);
	      PutKey(ch,sc);
	      DocLock(doc);
	    }
	}
	break;
    }
  } while (ch!=CH_ESC && ch!=CH_SHIFT_ESC);

  gr.fp_final_scrn_update=fp_old_final_scrn_update;
  Fs->put_doc	 =old_put_doc;
  Fs->display_doc=old_display_doc;
  SettingsPop;
  DocDel(doc);
  DirTreeDel(head);
  Cd(old_cur_dir);
  Free(old_cur_dir);
  if (mode!=FM_NORMAL && !res)
    res=StrNew("",mem_task);
  MenuPop;
  return res;
}
#help_index ""

#help_index "DolDoc/Input;File/FileNames;StdIn/DolDoc"
//ALL these PopUpPickers will be replaced, with a 
//generic function that excepts mode type.

public U8 *PopUpPickerGen(U8 *dir=NULL,I64 mode=FM_NORMAL)
{
  U8 *res,*st,*st2;
  if (dir)
    st=MStrPrint("Cd(\"%Q\");FileMgr(%d,Fs->parent_task);",dir,mode);
  else {
    st2=DirCur;
    st=MStrPrint("Cd(\"%Q\");FileMgr(%d,Fs->parent_task);",st2,mode);
    Free(st2);
  }
  res=PopUp(st,Fs);
  Free(st);
  return res;
}
public U8 *PopUpPickDirFile(U8 *dir=NULL)
{//Directory or Filename chooser.  Uses $LK,"FileMgr",A="MN:FileMgr"$().
  return PopUpPickerGen(dir,FM_PICK_DIRFILE);
}
public U8 *PopUpPickDirStrict(U8 *dir=NULL)
{//Directory chooser. Uses $LK,"FileMgr",A="MN:FileMgr"$().
 //Strict requires you to select a folder. Hitting ESC on a file,
 //won't extract return the containing folder, as the non-strict does.
  return PopUpPickerGen(dir,FM_PICK_DIRSTRICT);
}
public U8 *PopUpPickFileStrict(U8 *dir=NULL)
{//Directory chooser. Uses $LK,"FileMgr",A="MN:FileMgr"$().
 //Strict requires you to select a folder. Hitting ESC on a file,
 //won't extract return the containing folder, as the non-strict does.
  return PopUpPickerGen(dir,FM_PICK_FILESTRICT);
}
#help_index ""

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

//NEED to figure out, how to get WipeFunc to work, with these.
HijackFunc(&ACDWordsLoad,&acdwordsload);
HijackFunc(&CtrlAltT,&ctrlaltt);
HijackFunc(&DocEd,&doced);
HijackFunc(&DocEntryRun,&docentryrun);
HijackFunc(&DocPutKey,&docputkey);
HijackFunc(&DrvTextAttrGet,&drvtextattrget);
HijackFunc(&Ed,&ed);
HijackFunc(&FileMgr,&filemgr);

public U0 tdit()
{
  Copy("C:/Home/td/*.*","C:/Apps/templeDOS");
}