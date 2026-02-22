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

/*templeDOS.HC
  Description:
      Command-line interpreter for TempleOS.
*/
#ifndef TEMPLE_DOS_PATH
  Cd(__DIR__);;
  #include "load"
#endif

Bool inPickerLst(U8 *opt)
  return LstMatch(MStrUtil(opt,SUF_TO_UPPER),"τυ\0??\0?D\0?F\0?DM\0",LMF_EXACT);
Bool inLst(U8 *opt)
  return LstMatch(MStrUtil(opt,SUF_TO_UPPER),"ON\0OFF\0",LMF_EXACT)>-1;

Bool TF(I64 val) return val>0;

Bool WildCard(U8 *str)
{//Checking for any form, of wild card.
 //Real crude way to do this.
  if (!StrLen(str)) return FALSE;
//  if (!StrCmpEX(str,,"*",".")) return TRUE;
  if (*str=='.') return TRUE;
  if (StrOcc(str,'*')) return TRUE; // Works for: * or even ~/*HC
  return FALSE;
}

Bool SHOW_ANSWERS=TRUE;
Bool TIP_OF_DAY=TRUE;

/*COMMAND HISTORY stuff
EdLineDel(doc);
*/

//Was gonna put the help file in "::/Doc".
U8 *help_file=MStrPrint("%s/help.DD",__DIR__);
U8 *menu_file=MStrPrint("%s/menu.DD",__DIR__);

U8 prev_cmd[512];
U0 set_prevcmd(U8 *new_cmd) BuffStuff(prev_cmd,new_cmd);

U8 prev_dir[512];
U0 set_prevdir() BuffStuff(prev_dir,DirNameAbs(Fs->cur_dir));

U8 *f_str(U8 *cmd,U8 *arg) return MStrPrint("%s(\"%s\");",cmd,arg);

U8 *eptr=NULL; //cmd sent into the error function.
Bool f_err(U8 *flg_want,Bool prn_err=TRUE)
  return flag_err(a->flags,flg_want,prn_err,help_file,eptr);
U0 e_print(U8 *msg,U8 *link="Usage")
  err_print(msg,link,help_file,eptr);


U64 execute_cmd(U8 *cmd) {
  if (!StrLen(cmd)) return 0;

  //User is trying to normally run a OS command?
  if (cmd[StrLen(cmd)-1]==';') { 
    ExePutS(cmd); return 0;
  }

  if (SHOW_ANSWERS) F64 t0=tS,t1;

  Fs->answer=0;

  a->init(a);
  if (!a->parse(a,cmd)) goto answer; //Parsed no args

  Fs->answer=1;

  I64 res,idx;res=idx=0;

hashit:
  if ((idx=c->hashdx(c,a->args[0]))==-1)
  {
    if (!StrCmp(a->args[0],"##")) { //pid
      BuffStuff(a->args[0],"pid"); goto hashit;
    }
    if (!StrCmp(a->args[0],":>")) { //touch
      BuffStuff(a->args[0],"touch"); goto hashit;
    }

//drvchange:
    //Switching drives DOS style?
    if (StrLen(a->args[0])==2) {
      if (a->args[0][1]==':') {
        if (a->count>1) { e_print(ERR_ARGC); goto answer; }

        if (Fs->answer=DrvMounted(a->args[0])) {
          set_prevdir;
          Drv(a->args[0][0]);
          goto error;
        }
        else { e_print(ERR_DRVIU,a->args[0]); goto answer; }
      }
    }
//drvchange_end:

    idx=999; 
    goto switchit;
  } 
hashit_end:

  I64 v=0,fc;

  fc=flag_cnt(a->flags);

//error_handler:
  eptr=c->data[idx][TOK_CMD];

  //Valid argument and flag count start
  if (!c->tk_minmax(c,idx,a->count-(fc>0))) {
    e_print(ERR_ARGC); goto answer; }
  if (!c->tk_minmax(c,idx,fc,HFLAGS)) {
    e_print(ERR_FLGC); goto answer; }
  //Valid argument and flag count end

//error_handler_end:

//help start
  if (a->count==2&&fc) {
    if (!f_err(FLG_H,FALSE)) {
      Ed(MStrPrint("FF:%s,_%s",help_file,eptr)); goto answer;
    }
  }
//help end

  //CMD: No args or flags
  if (c->data[idx][TOK_MAX]==1) goto switchit;

  U8 *bufa,*bufb;

  a->next(a);bufa=a->get_current(a);
  a->next(a);bufb=a->get_current(a);

  U64 bav,bbv; bav=bbv=0;

//Pick file support start
  I64 p1,p2,p3; p1=p2=p3=0;

  if (a->count==2) bufb=StrNew("");

  p1=p3=inPickerLst(bufa); p2=inPickerLst(bufb);

  if ((p1==-1)&&(p2==-1)) goto pickit_end;

  if (a->count==2) p2=0;

  v.u8[0]=TF(p1);v.u8[1]=TF(p2);

  if (v.u8[0]||v.u8[1]) {
    U64 ui=1-v.u8[0],vt;

    U8 p[512];

    Bool od=(c->data[idx][TOK_ATYPE]==ONLY_DIRS),
	 of=(c->data[idx][TOK_ATYPE]==ONLY_FILES);

pickit:
    vt=ui*3;

    if (ui==1) p3=p2;

    p3--;//Cause we don't want zeroes.  See the list.

    //Just one silent error prevention method.  I'll look at making
    //error handling, for source and destination arguments. But,
    //this will stop: `cat ?D` giving you `cat C:/Home`
    if (od) p3=1;
    if (of) p3=2;

    switch (idx) {
    start:
      case  30: //rmdir
      case  43: //cdd
      case 199: //cd
      case 214: //rd
        p3=1;
      default:
        if (p3==1||p3==3)
        {
          BuffStuff(p,StrNew(PopUpPickDirStrict));
          v.$WW+H,1$u8[vt+DIR]=1*(StrLen(p)>0);

          if (p3==3&&StrLen(p)>0) CatPrint(p,"/*.*");
        }
        if (p3==0||p3==2)
        {
          BuffStuff(p,StrNew(PopUpPickFileStrict));
          v.$WW+H,1$u8[vt+FILE]=1*(StrLen(p)>0);
        }
    end:

      if (ui==0) BuffStuff(bufa,p);
      else BuffStuff(bufb,p);

      break;
    }

    if (ui==0&&v.u8[1]) {
      ui++; goto pickit;
    }

    if (v.u8[DIR]&&ui==1) {
      if (!IsDir(bufb)) {
        e_print(ERR_DIRSRCDST); goto error;
      }
      else {
	bav=bbv=TRUE; goto switchit;
      }
    }
  }

pickit_end:
//Pick file support end

  //In case, you don't feel like providing a file extension ".HC".
  if (I64Cmp(idx,86)) { 
    BuffStuff(bufa,ExtDft(bufa,"HC"));
  }

//validation:
  //Wild card support-ls,grep, etc
  Bool wild=WildCard(bufa);
  if (wild) {
    if (I64Cmp(idx,64,174,176,211,223,224)) {
      if (*bufa=='.') *bufa='*';
      bav=TRUE; goto dont_validate;
    }
  }

  if (idx==174) goto dont_validate;

  v=files_valid(bufa,bufb);
  bav=v.u8[0]; bbv=v.u8[1];

dont_validate:
//validation_end:

  U8 bufe[255]=NULL;

//filesexist:
  //CMD: File(s) need to exist
  //EXCLUDE 35,201
  I64 fci=0;
  if (I64Cmp(idx,211,227)) { //cp,mv
    if (I64Cmp(fci=MaxI64(0,file_char2(*bufa)),2,5)) {
      bav=TRUE; goto switchit; }
  }
//  if (I64Cmp(idx,30,56,86,146,153,170,179,
  if (I64Cmp(idx,30,56,86,146,170,179,
      182,187,194,208,211,214,224,227)) {
    if (!bav) { BuffStuff(bufe,bufa); goto nferror; }

    switch(idx)
    {
      case 30: case 214:
      case 224: //rm,rd,rmdir
        goto switchit;
        break;
      case 153: //diff
        if (!bbv) { BuffStuff(bufe,bufb); goto nferror; }
        if (!type_got(v,FILE,1)) goto answer;
        break;
      case 211: //cp
        if (fc) {
          if (f_err(FLG_D)) goto answer;
          if (!type_got(v,DIR)) goto answer;

          break;
        }
        if (fci) break;
      default:
        if (!type_got(v,FILE)) goto answer;
    }
  }
//filesexist_end:

  U64 be=FALSE;

  switch(idx)
  {
    case 201:
    bufa=MStrPrint("%s",FileNameAbs(bufa));
  }  

  switchit:  
    set_prevcmd(cmd);
  switch[idx] //idx should never be outside the range of this switch
  {
    case   7: //clear
    case  66: //cls
      DocClear;
      break;
    case  23: //mkdir
   case  209: //md
      if (!bav) DirMk(bufa);
      else
        if (type_got(v,DIR))
          e_print(ERR_DIR_EXISTS,bufa);
        else
          e_print(ERR_DRVFILEIDIR,bufa);

        goto answer;
      break;
    case  30: //rmdir
    case 214: //rd
    case 224: //rm
      Bool trash=!f_err(FLG_T,FALSE);
      if (trash) {
        dump_exists;
        Silent(ON);
      }

      fc-=trash;

      if (fc) {
        if (f_err(FLG_D)) goto answer; idx=30;
      }

      if (idx==224) {
        if (!wild)
          if (!type_got(v,FILE)) goto answer;

        if (trash) Move(bufa,TRASH_DIR);
        else Del(bufa);
      }
      else
      {
        if (!type_got(v,DIR)) goto answer;

        if (trash) CopyTree(bufa,MStrPrint("%s/%s",TRASH_DIR,bufa));

        DelTree(bufa);
      }

      if (trash) trash_msg(bufa);

      break;
    case  35: //touch
      if (bav) Touch(bufa,""); //Update time & date
      else
       if (filenameOK(bufa)) FileWrite(bufa,NULL,0); //Create file
       else { e_print(ERR_FILEI,"info"); goto answer; }

      break;
    case  38: //tasks
    case 228: //ps
      TaskRep;

      break;
    case  43: //cdd
    case 199: //cd
      if (a->count==1) { BuffStuff(bufe,"~"); goto prevdir; } //~

      if (a->count==2&&fc==0)
        if (StrLen(bufa)==0) { BuffStuff(bufe,prev_dir); goto prevdir; } //-

      if (!StrCmp(bufa,"::")) { BuffStuff(bufe,bufa); goto prevdir; } //::

      BuffStuff(bufe,bufa);

      if (!bav) goto nferror;
      if (!type_got(v,DIR,,FALSE)) {
        e_print(ERR_FILEIDRVDIR,bufa); goto answer;
      }

      prevdir:
        set_prevdir;
        Cd(bufe);
        if (idx==43) ls;
        ACDirList;

      break;
    case  56: //cat
    case 187: //view
    case 194: //type
//      "%F",bufa;
      viewer(f_str("Type",FileNameAbs(bufa)));

      break;
    case  60: //man
      if (!(Fs->answer=Man(bufa)))
       "No symbol entry found for $$RED$$%s$$FG$$\n",bufa;

      break;
    case  61: //pal
      if (fc)
      {
        if (be=!f_err(FLG_P,FALSE))
          Fs->answer=PopUpColor;
         
        if (!be) if (!f_err(FLG_D))
          Fs->answer=PopUpColorDither;

        break;
      }

      U64 i=0;
      while (i<COLORS_NUM)
      {
        "$$FG,%d$$Ϋ",i;i++;
      }"\n";

      break;
    case  62: //pid
      "Process ID: %X\n",Fs;
      break;
    case  63: //mem
      //MemBIOSRep; PCIRep;
      viewer("MemRep;\"\n\";
              MemPageRep;MemBIOSRep;\"\n\";");

      break;
    case  67: //ans
      if (a->count>1)
        if (!(be=inLst(bufa))) { e_print(ERR_FLGI); break; }

      SHOW_ANSWERS=a->count==1||!StrICmp(bufa,"ON");

      break;
    case 68: //rnd <-Generate a GOD number, for Terry
      "Press <ESC> to recieve your GOD number:";
      "%X\n",god_num(Fs->display_doc);

      break;
    case  72: //cpu
      if (fc)
        if (f_err(FLG_F)) goto answer;

      CPURep(fc);

      break;
    case 75: //pwd
      "%s\n",__DIR__;

      break;
    case  81: //vol
        //Don't think drives have labels in this OS.
        "Volume in drive %c: has no label.\n",CurDrv;
        "Volume Serial Number is %s\n",DrvSerialNum(CurDrv);

      break;
    case  84: //now
      "%D %T\n",Now,Now;

      break;
    case  86: //run
      Fs->answer=ExeFile(bufa);

      break;
    case 146: //head
      Head(bufa);

      break;
    case 153: //diff
      Diff(bufa,bufb);

      break;
    case 158: //date
      "%D\n",Now;

      break;
    case 169: //help
      if (!FileFind(help_file)) { e_print(ERR_NF,help_file); goto answer; }

      viewer(f_str("Type",help_file));

      break;
    case 170: //tail
      Tail(bufa);

      break;
    case 174: //grep
      if (fc) {

        if (f_err(FLG_D)) goto answer;
        Fs->answer=FD(StrNQ(bufa));
      }
      else Fs->answer=F(StrNQ(bufa));

      break;
    case 177: //time
      "%T\n",Now;

      break;
    case 179: //more
      More(bufa);

      break;
    case 182: //dump
      Dump(bufa);

      break;
    case 184: //term
      User;

      break;
    case 186: //exit
    case 195: //quit
      res=1;

      break;
    case 201: //ed
      if (filenameOK(bufa)) PopUpEd(bufa);
      else { e_print(ERR_FILEI,bufa); goto answer; }

      break;
    case 203: //df
      DrvRep; "\n";
      DrvFree;

      break;
    case 208: //tosz
      Silent(ON);
      Move(bufa,ToggleZorNotZ(bufa));

      break;
    case 211: //cp
      if (fc) {
        //I restrict * and . to file copying.
        //CopyTree(); does support them.
        CopyTree(bufa,bufb);
      }
      else
        Copy(bufa,bufb);

      break;
    case 212: //fm
      FileMgr;

      break;
    case  64: //dir
    case 176: //tree
    case 223: //ls
      if (fc)
        if (f_err(FLG_T)) goto answer;

      BuffStuff(bufe,bufa);

      if (a->count==1) BuffStuff(bufe,".");

      
      ls(bufe,(fc||idx==176));"\n";

      break;
    case 227: //mv
//Possibly add flags to specify destination type dir/file.
//Could then check existance of destination folders & such.
      if (type_got(v,DRV,,FALSE)) {
        e_print(ERR_DRVIDIRFILE,bufa);
        goto answer;
      }

      Silent(ON);
      Move(bufa,bufb);
      Silent(OFF);
      "Moved: %s to %s\n",bufa,bufb;

      break;
    case 999:
      goto unknown;
      break;
    default:
      Fs->answer=ExePutS(cmd); //Probably never get in here.
  }
  goto error;

unknown:
  e_print(ERR_UNKNOWN,"info");
  goto answer;

nferror:
  err_print(ERR_NF,bufe);

answer: //Possibly rename
  Fs->answer=0;

error:
  if (SHOW_ANSWERS) {
    t1=tS-t0;
    "\n%8.6fs ans=0x%08X=%d\n",t1,t1,Fs->answer;
  }

  Silent(OFF);

  return res;
}

U0 stop_ctrl_alt_x() XTalk(Fs,"exit\n");

U8 templeDOS() {
  SettingsPush;

  Fs->cur_menu=MenuFile(menu_file);

  Fs->task_end_cb=&stop_ctrl_alt_x;

  Seed; I64 termID=AbsI64(RandI32);

//  AdamLog("\nBoot Time:%7.3fs\n\n",tS);

//  FF("/*BIN*");
  AdamLog("\n\n$$LTCYAN$$TODO:  ** - globstar support$$FG$$ ...\n\n");
//  AdamLog("templeDOS [%d]: started: %D %T\n",termID,Now,Now);

  set_windowinfo(MStrPrint("templedos_task%d",termID),"TempleDOS");

  DocClear;DocMax;Cd;

  ACDirList;

  if (TIP_OF_DAY) {
    "\n$$LTCYAN$$Tip of the day:$$FG$$";TipOfDay;
  }

  "\n$$LTGREEN$$TempleDOS$$FG$$ {$$YELLOW$$Version 1.0$$FG$$}\n";
  "(c) 2024 No rights reserved. For Public Domain use.\n";
  "Type '$$LTRED$$help$$FG$$' for internal command list.";
  "\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  U64 res=0;
  U8 input[512];

  while (TRUE)
  {
    DocBottom;
    "\n%c:%s: ",CurDrv,Fs->cur_dir; // Display prompt
    BuffStuff(input,MyGetStr(GSF_SHIFT_ESC_EXIT));

    if (input[0]=='ι') break;

    if (!StrCmp(input,"!!")) {
      BuffStuff(input,prev_cmd);
    }

    if (res=execute_cmd(input)) break;
  }

//  AdamLog("templeDOS [%d]: terminated: %D %T\n",termID,Now,Now);

  DocBottom; "\n$$FG$$";

  SndRst;

  MenuPop;

  SettingsPop;

  return res;
}
