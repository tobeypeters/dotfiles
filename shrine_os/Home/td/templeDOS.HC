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

/*COMMAND HISTORY stuff
EdLineDel(doc);
*/

//Was gonna put the help file in "::/Doc".
U8 *help_file=strnew(,,__DIR__,"/help.DD");
U8 *menu_file=strnew(,,__DIR__,"/menu.DD");

U8 *prev_cmd='\0';
U0 set_prevcmd(U8 *newcmd) {
  zFree(prev_cmd);
  prev_cmd=StrNew(newcmd);
}

U8 *prev_dir='\0';
U0 set_prevdir() {
  zFree(prev_dir);
  prev_dir=StrNew(DirNameAbs(Fs->cur_dir));
}

U8 *f_str(U8 *cmd,U8 *arg) return MStrPrint("%s(\"%s\");",cmd,arg);
U8 *eptr=NULL; //cmd sent into the error function.
U8 *fptr=NULL; //ptr to a->flags
Bool f_err(U8 *flg_want,Bool prn_err=TRUE)
  return flag_err(fptr,flg_want,prn_err,help_file,eptr);
U0 e_print(U8 *msg,U8 *link="Usage")
  err_print(msg,link,help_file,eptr);

U8 execute_cmd(U8 *cmd) {
  set_prevcmd(cmd);

  U8 *bufe=CAlloc(sizeof(U8)*128); //scratch buffer

  a->init(a);
  a->parse(a,cmd);

  if (a->count==0) goto error;

  I64 res,idx;
  res=idx=0;

  if ((idx=c->hashdx(c,a->args[0]))==-1)
  {
    //Switching drives DOS style?
    if (str_len(a->args[0])==2) {
      if (a->args[0][1]==':') {
        if (a->count>1) { e_print(ERR_ARGC); goto error; }

        if (drv_mounted(a->args[0])) {
          set_prevdir;
          Drv(a->args[0][0]);
        }
        else e_print(ERR_DRVIU,a->args[0]);
        goto error;
      }
    }

    //try to "shell" execute it
    idx=999; 
    goto switchit;
  }

  I64 v,fc;
  v=fc=0;

  eptr=c->data[idx][1];
  fptr=a->flags;

  fc=flag_cnt(a->flags);

  if (a->count==2&&fc) {
    if (!f_err(FLG_H,FALSE)) {
      Ed(str_cat(bufe,,"FF:",help_file,",_",eptr)); goto error;
    }
  }

  if (!I64_between(a->count-(fc>0),c->data[idx][2],(c->data[idx][3]-c->data[idx][4]))) {
    e_print(ERR_ARGC); goto error; }

  if (!I64_between(fc,0,c->data[idx][4])) {
    e_print(ERR_FLGC); goto error; }

  U8 *bufa,*bufb;

  a->next(a);bufa=a->get_current(a);
  a->next(a);bufb=a->get_current(a);

  if (idx==174) goto switchit; //grep

  v=files_valid(bufa,bufb);
  U64 bav=v.u8[0];

  bav=(bav|(a->count==1));

  if (I64_IN(idx,30,56,86,179,
      182, 187,211,214,224,227)) if (!bav) goto nferror;

  Bool be=FALSE; //General purpose bool
 
  switchit:  
  switch[idx] //idx should never be outside the range of this switch
  {
    case   7: //clear
      DocClear;
      break;
    case  23: //mkdir
      if (!bav) DirMk(bufa);
      else
        if (type_got(v,DIR))
          e_print(ERR_DIR_EXISTS,bufa);
        else
          e_print(ERR_DRVFILEIDIR,bufa);

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

      if (fc)
        if (f_err(FLG_D)) break;

      if (I64_IN(idx,30,214) || 224 && fc) {
        if (trash)
          if (type_exec(v,DIR,,,"CopyTree",bufa,TRASH_DIR))
            trash_msg(bufa);

        t_exec(v,DIR,f_str("DelTree",bufa));

        break;
      }

      if (trash) 
        if (type_exec(v,FILE,,,"Move",bufa,TRASH_DIR)) trash_msg(bufa);
      else
        t_exec(v,FILE,f_str("Del",bufa));

      break;
    case  35: //touch
      if (bav) type_exec(v,FILE,,,"Touch",bufa,"\"\""); //Update time & date
      else
       if (filenameOK(bufa)) FileWrite(bufa,NULL,0); //Create file
       else e_print(ERR_FILEI,"info");

      break;
    case  38: //tasks
      TaskRep;

      break;
    case  43: //cdd
    case 199: //cd
      if (a->count==1) { bufe=StrNew("~"); goto prevdir; } //~
      if (a->count==2&&fc==0)
        if (str_len(bufa)==0) { bufe=StrNew(prev_dir); goto prevdir; } //-
      if (str_cmp(bufa,"::")) { bufe=StrNew("::"); goto prevdir; } //::
      if (!bav) { e_print(ERR_NF,bufa); goto nocd; }
      if (type_got(v,FILE,,FALSE)) { e_print(ERR_FILEIDRVDIR,bufa); goto nocd; }
      
      bufe=StrNew(bufa);
 
      prevdir:
        set_prevdir;
        Cd(bufe);
        if (idx==43) ls;
      nocd:
        break;
    case  56: //cat
    case 187: //view
      type_exec(v,FILE,,,"viewer",
                str_cat(bufe,,"Type(\\\"",bufa,"\\\");"));

      break;
    case  60: //man
      if (!Man(bufa)) "No symbol entry found for $$RED$$%s$$FG$$\n",bufa;

      break;
    case  61: //pal
      if (fc)
      {
        if (be=!f_err(FLG_P,FALSE))
          PopUpColor;
         
        if (!be) if (!f_err(FLG_D))
          PopUpColorDither;

        break;
      }

      U64 i=0;
      while (i<16)
      {
        "$$FG,%d$$Û",i;i++;
      }"\n";

      break;
    case  63: //mem
      viewer("MemRep;\"\n\";
              MemPageRep;\"\n\";");

      break;
    case 68: //rnd <-Generate a GOD number, for Terry
      "%X\n",god_num(Fs->display_doc);

      break;
    case  72: //cpu
      if (fc)
        if (f_err(FLG_F)) break;

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
      t_exec(v,FILE,f_str("ExeFile",bufa));

      break;
    case 146: //head
      t_exec(v,FILE,f_str("Head",bufa));

      break;
    case 158: //date
      "%D\n",Now;

      break;
    case 169: //help
      if (!FileFind(help_file)) { e_print(ERR_NF,help_file); break; }

      if (bav) viewer(f_str("Type",help_file));

      break;
    case 170: //tail
      t_exec(v,FILE,f_str("Tail",bufa));

      break;
    case 174: //grep
      F(str_NQ(bufa));

      break;
    case 177: //time
      "%T\n",Now;

      break;
    case 179: //more
      t_exec(v,FILE,f_str("More",bufa));

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
      type_exec(v,FILE,,,"Silent(ON);Move",bufa,ToggleZorNotZ(bufa));

      break;
    case 211: //cp
      if (fc) {
        if (f_err(FLG_D)) break;
        type_exec(v,DIR,,,"CopyTree",bufa,bufb);
      }
      else type_exec(v,FILE,,,"Copy",bufa,bufb);

      break;
    case 212: //fm
      FileMgr;

      break;
    case 176: //tree
    case 223: //ls
      if (!bav)
        if(str_len(bufa)) goto nferror;

      if (fc)
        if (f_err(FLG_T)) break;

      bufe=StrNew(bufa);

      if (a->count==1) bufe=StrNew(".");

      if (a->count==2)
        if (str_cmp(bufa,"-")) bufe=StrNew(prev_dir);
      
      ls(bufe,(fc||idx==176));"\n";

      break;
    case 227: //mv
      if (type_got(v,DIR,,FALSE)) {
        shell_exec("CopyTree",,bufa,bufb);
        shell_exec("DelTree",,bufa);
      }
      else {
        if (type_got(v,DRV,,FALSE)) {
          e_print(ERR_DRVIDIRFILE,bufa);
          break;
        }
        shell_exec("Move",,bufa,bufb);
      }

      break;
    case 999:
    default:
      shell_exec("",TRUE,a->args[0]); //User is trying to normally run a OS command?
  }
  goto error;

nferror:
  err_print(ERR_NF,bufa);

error:
  Silent(OFF);
  zFree(bufe);
  return res;
}

U8 templeDOS() {
  Seed; I64 termID = AbsI64(RandI32);

//  Adam("\"\nBoot Time:%%7.3fs\n\n\",tS;");

//  Adam("\"\n\n$$LTCYAN$$TODO:$$FG$$ grep - allow quoted strings ...\n\n\";");

  Adam("\"templeDOS [%d]: started: %D %T\n\";",termID,Now,Now);

  set_windowinfo("templedos_task","TempleDOS");

  DocClear; DocMax;

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

    if (str_cmp(input,"-1")) {
      zFree(input);
      input=StrNew("exit");
    }

    if (str_cmp(input, "!!")) {
      zFree(input);
      input=StrNew(prev_cmd);
    }

    res=execute_cmd(input);

    zFree(input,FALSE);

    if (res==1) break;
  }

  zFree(input);

  Adam("\"templeDOS [%d]: terminated : %D %T\";",termID,Now,Now);

  return res;
}

U0 stop_ctrl_alt_x() XTalk(Fs,"exit\n");

SettingsPush;

Fs->cur_menu=MenuFile(menu_file);

Fs->task_end_cb=&stop_ctrl_alt_x;

Cd;set_prevdir;

templeDOS;

a->init(a);
zFree(a);
zFree(c);

zFree(prev_dir);
zFree(menu_file);
zFree(help_file);

DocBottom; "$$FG$$";

MenuPop;
SettingsPop;

