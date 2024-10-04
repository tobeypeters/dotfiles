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

Bool inLst(U8 *opt)
  return LstMatch(MStrUtil(opt,SUF_TO_UPPER),"ON\0OFF\0",LMF_EXACT)>-1;

Bool SHOW_ANSWERS=TRUE;
Bool TIP_OF_DAY=TRUE;

/*COMMAND HISTORY stuff
EdLineDel(doc);
*/

//Was gonna put the help file in "::/Doc".
U8 *help_file=MStrPrint("%s/help.DD",__DIR__);
U8 *menu_file=MStrPrint("%s/menu.DD",__DIR__);

U8 *prev_cmd=NULL;
U0 set_prevcmd(U8 *newcmd) {
  if (StrLen(prev_cmd)) Free(prev_cmd);
  prev_cmd=StrNew(newcmd);
}

U8 *prev_dir=NULL;
U0 set_prevdir() {
  if (StrLen(prev_dir)) Free(prev_dir);
  prev_dir=DirNameAbs(Fs->cur_dir);
}

U8 *f_str(U8 *cmd,U8 *arg) return MStrPrint("%s(\"%s\");",cmd,arg);

U8 *eptr=NULL; //cmd sent into the error function.
Bool f_err(U8 *flg_want,Bool prn_err=TRUE)
  return flag_err(a->flags,flg_want,prn_err,help_file,eptr);
U0 e_print(U8 *msg,U8 *link="Usage")
  err_print(msg,link,help_file,eptr);

U8 execute_cmd(U8 *cmd) {
  U8 *bufe=NULL; //scratch buffer

  if (SHOW_ANSWERS) F64 t0=tS,t1;

  //User is trying to normally run a OS command?
  if (cmd[StrLen(cmd)-1]==';') {
    ExePutS(cmd); return 0;
  }

  a->init(a);
  if (!a->parse(a,cmd)) goto answer; //Parsed no args

  Fs->answer=1;

  I64 res,idx;res=idx=0;
  if ((idx=c->hashdx(c,a->args[0]))==-1)
  {
    //Switching drives DOS style?
    if (StrLen(a->args[0])==2) {
      if (a->args[0][1]==':') {
        if (a->count>1) { e_print(ERR_ARGC); goto answer; }

        if (Fs->answer=drv_mounted(a->args[0])) {
          set_prevdir;
          Drv(a->args[0][0]);
          goto error;
        }
        else { e_print(ERR_DRVIU,a->args[0]); goto answer; }
      }
    }

    idx=999; 
    goto switchit;
  }

  I64 v,fc;v=fc=0;

  fc=flag_cnt(a->flags);

  eptr=c->data[idx][1];

  if (!c->tk_minmax(c,idx,a->count-(fc>0))) {
    e_print(ERR_ARGC); goto answer; }
  if (!c->tk_minmax(c,idx,fc,HFLAGS)) {
    e_print(ERR_FLGC); goto answer; }

  if (a->count==2&&fc) {
    if (!f_err(FLG_H,FALSE)) {
      Ed(MStrPrint("FF:%s,_%s",help_file,eptr)); goto answer;
    }
  }

  //CMD: No args or flags
  if (I64_IN(idx,7,38,61,63,66,68,72,75,81,84,158,
      169,177,184,186,195,203,212,228)) goto switchit;

  U8 *bufa,*bufb;

  a->next(a);bufa=a->get_current(a);
  a->next(a);bufb=a->get_current(a);

  U64 bav,bbv; bav=bbv=0;

  //Pick file support
  if (a->count>1) {
    if (v.u8[0]=!StrCmp(bufa,"??")||
        v.u8[1]=!StrCmp(bufb,"??")) {
      U64 vt=v.u8[0]*3;
      switch (idx) {
        case  43: //cdd
        case 199: //cd
          bufa=StrNew(PopUpPickDir);
          v.u8[vt+DIR]=1;

          break;
        case 211: //cp
        case 227: //mv
          if (fc)
          if (f_err(FLG_D)) {
            if (v.u8[0]) bufa=StrNew(PopUpPickDir);
            else bufb=StrNew(PopUpPickDir);

            v.$WW+H,1$u8[vt+DIR]=1;

            break;
          }

          if (v.u8[0]) bufa=StrNew(PopUpPickFile);
          else bufb=StrNew(PopUpPickFile);

          v.$WW+H,1$u8[vt+FILE]=1;

          break;
        default:
          bufa=StrNew(PopUpPickFile);
          v.$WW+H,1$u8[vt+FILE]=1;
      }

      bav=TRUE; goto switchit;
    }
  }

  //Wild card support,grep
  if (!(*bufa=='*')&&!(idx==174)) {
    v=files_valid(bufa,bufb);
    bav=v.u8[0]; bbv=v.u8[1];
//    bav=(v.u8[0]|(a->count==1)); //Was for NO ARG & NO FLAGS COMMANDS
  }

  //CMD: File(s) need to exist
  //EXCLUDE 35,201
  //153: diff
  if (I64_IN(idx,56,86,146,153,170,179,
      182,187,194,208)) {
    if (!bav) { bufe=bufa; goto nferror; }

    if (idx==153)
      if (!bbv) { bufe=bufb; goto nferror; }

    if (!type_got(v,FILE)) goto answer;
    if (idx==153)
      if (!type_got(v,FILE,1)) goto answer;
  }

  U64 be=FALSE;

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
        if (idx==224)
          if (f_err(FLG_D)) goto answer;

        e_print(ERR_FLGI,"info");
        goto answer;
      }

      if (I64_IN(idx,30,214) || 224 && fc) {
        if (!type_got(v,DIR)) goto answer;

        if (trash) {
          CopyTree(bufa,TRASH_DIR);
          trash_msg(bufa);
        }
        DelTree(bufa);
        break;
      }

      if (!type_got(v,FILE)) goto answer;
      if (trash) {
        Move(bufa,TRASH_DIR);
        trash_msg(bufa);
      }
      else
       Del(bufa);

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
    case 199: //cd;
      if (a->count==1) { bufe=StrNew("~"); goto prevdir; } //~
      if (a->count==2&&fc==0)
        if (str_len(bufa)==0) { bufe=StrNew(prev_dir); goto prevdir; } //-
      if (str_cmp(bufa,"::")) { bufe=bufa; goto prevdir; } //::

      bufe=StrNew(bufa);

      if (!bav) goto nferror;
      if (!type_got(v,DIR,,FALSE)) {
        e_print(ERR_FILEIDRVDIR,bufa); goto answer;
      }

      prevdir:
        set_prevdir;
        Cd(bufe);
        if (idx==43) ls;

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
      while (i<16)
      {
        "$$FG,%d$$Û",i;i++;
      }"\n";

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
        "Volume in drive %c: has no label.\n",cur_drv;
        "Volume Serial Number is %s\n",DrvSerialNum(cur_drv);

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
        Fs->answer=FD(str_NQ(bufa));
      }
      else Fs->answer=F(str_NQ(bufa));

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
      if (filenameOK(bufa)) Ed(bufa);
      else e_print(ERR_FILEI,bufa);

      break;
    case 203: //df
      DrvRep; "\n";
      drv_free;

      break;
    case 208: //tosz
      Silent(ON);
      Move(bufa,ToggleZorNotZ(bufa));

      break;
    case 211: //cp
      if (fc) {
        if (f_err(FLG_D)) goto answer;
        if (!type_got(v,DIR)) goto answer;

        CopyTree(bufa,bufb);
      }
      else {
        if (!type_got(v,FILE)) goto answer;

        Copy(bufa,bufb);
      }

      break;
    case 212: //fm
      FileMgr;

      break;
    case 176: //tree
    case 223: //ls
      if (fc)
        if (f_err(FLG_T)) goto answer;

      bufe=StrNew(bufa);

      if (a->count==1) bufe=StrNew(".");

      if (a->count==2)
        if (str_cmp(bufa,"-")) bufe=StrNew(prev_dir);
      
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
  bufe=NULL;

answer: //Possibly rename
  Fs->answer=0;

error:
  if (SHOW_ANSWERS) {
    t1=tS-t0;
    "\n%8.6fs ans=0x%08X=%d\n",t1,t1,Fs->answer;
  }

  Silent(OFF);
//  bufa=bufb;

  zFree(bufe);

  return res;
}

U8 templeDOS() {
  Seed; I64 termID=AbsI64(RandI32);

//  Adam("\"\nBoot Time:%%7.3fs\n\n\",tS;");

//  FF("/*BIN*");
  Adam("\"\n\n$$LTCYAN$$TODO:$$FG$$ ...\n\n\";");
  Adam("\"templeDOS [%d]: started: %D %T\n\";",termID,Now,Now);

  set_windowinfo("templedos_task","TempleDOS");

  DocClear;DocMax;Cd;

  if (TIP_OF_DAY) {
    "\n$$LTCYAN$$Tip of the day:$$FG$$";TipOfDay;
  }

  "\nTempleDOS {Version 1.0}\n";
  "(c) 2024 No rights reserved. For Public Domain use.\n";
  "Type 'help' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  U64 res=0;
  U8 *input=NULL;

  while (TRUE)
  {
    DocBottom;
    "\n%c:%s: ",(cur_drv),Fs->cur_dir; // Display prompt
    input=MyGetStr(GSF_SHIFT_ESC_EXIT);

    if (*input=='é') break;

    if (str_cmp(input, "!!")) {
      zFree(input);input=StrNew(prev_cmd);
    }

    if (res=execute_cmd(input)) break;

    zFree(input,FALSE);
  }

  zFree(input);

  Adam("\"templeDOS [%d]: terminated: %D %T\n\";",termID,Now,Now);

  return res;
}

U0 stop_ctrl_alt_x() XTalk(Fs,"exit\n");

SettingsPush;

Fs->cur_menu=MenuFile(menu_file);

Fs->task_end_cb=&stop_ctrl_alt_x;

templeDOS;

a->init(a);
Free(a);
Free(c);

eptr=NULL;
zFree(prev_dir);
zFree(menu_file);
zFree(help_file);

DocBottom; "$$FG$$";

MenuPop;

SettingsPop;
