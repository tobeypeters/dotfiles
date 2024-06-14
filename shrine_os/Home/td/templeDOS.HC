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
//Was gonna put the help file in "::/Doc".
//#include "~/td/debug"

/*COMMAND HISTORY stuff
EdLineDel(doc);
*/

U8 *help_file=strnew(,,__DIR__,"/help.DD");
U8 *menu_file=strnew(,,__DIR__,"/menu.DD");

U8 *prev_cmd='\0';
U8 *prev_dir='\0';

U0 set_prevcmd(U8 *newcmd) {
  zFree(prev_cmd);
  prev_cmd=StrNew(newcmd);
}

U0 set_prevdir() {
  zFree(prev_dir);
  prev_dir=StrNew(DirNameAbs(Fs->cur_dir));
}

U8 execute_cmd(U8 *cmd) {
  set_prevcmd(cmd);

  U8 *bufe=CAlloc(sizeof(U8)*128); //scratch buffer

  a->init(a);
  a->parse(a, cmd);

  if (a->count==0) goto error;

  I64 res,idx,v,fc;
  res=idx=v=fc=0;

  if ((idx=c->hashdx(c,a->args[0]))==-1)
  {
    //Switching drives DOS style?
    if (str_len(a->args[0])==2) {
      if (a->args[0][1]==':') {
        if (a->count>1) { err_print(ERR_ARGC); goto error; }

        if (drv_mounted(a->args[0])) {
          set_prevdir;
          Drv(a->args[0][0]);
        }
        else err_print(ERR_DRVIU,a->args[0]);
        goto error;
      }
    }

    //try to "shell" execute it
    idx=999; 
    goto switchit;
  }

  fc=flags_val(a->flags);
  fc=fc.u8[7];

/*  //c->data[3] == Token Max: Includes cmd,flags,and args
  U8 *test=MStrPrint("
fc: %d
a->count: %d
a->count-(fc>0): %d
c->data[idx][3]: %d
c->data[idx][4]: %d
(c->data[idx][3]-c->data[idx][4]): %d\n",
fc,a->count,
a->count-(fc&0),
c->data[idx][3],
c->data[idx][4],
(c->data[idx][3]-c->data[idx][4]));

  debug_prn(test,TRUE);

  zFree(test);
*/
  U8 *err_cmd=c->data[idx][1]; //Passed into the err_print;

  if (a->count==2&&fc) {
    if (!flag_err(a->flags,FLG_H,FALSE,help_file,err_cmd)) {
      Ed(str_cat(bufe,,"FF:",help_file,",_",err_cmd)); goto error;
    }
  }

  if (!I64_between(a->count,c->data[idx][2],c->data[idx][3])) {
    err_print(ERR_ARGTC,,help_file,err_cmd); goto error; }

  if (!I64_between(a->count-(fc>0),c->data[idx][2],(c->data[idx][3]-c->data[idx][4]))) {
    err_print(ERR_ARGC,,help_file,err_cmd); goto error; }

  if (!I64_between(fc,0,c->data[idx][4])) {
    err_print(ERR_FLGC,,help_file,err_cmd); goto error; }

  U8 *bufa,*bufb;

  a->next(a);bufa=a->get_current(a);
  a->next(a);bufb=a->get_current(a);

  v=files_valid(bufa,bufb);
  U64 bav=v.u8[0];

  bav=(bav|(a->count==1));

  if (I64_IN(idx,30,56,86,179,
      182, 187,211,214,224,227)) if (!bav) goto nferror;
 
  switchit:  
  switch[idx] //idx should never be outside the range of this switch
  {
$PT$$FG$$BG$    case   7: //clear
      DocClear;
      break;
    case  23: //mkdir
      if (!bav) DirMk(bufa);
      else
        if (type_got(v,DIR))
          err_print(ERR_DIR_EXISTS,bufa);

      break;
    case  30: //rmdir
    case 214: //rd
    case 224: //rm
      if (I64_IN(idx,30,214) || fc) 
      {
        if (idx==224)
          if (flag_err(a->flags,FLG_D,,help_file,err_cmd)) break;
        type_exec(v,DIR,,,"DelTree",bufa);
        break;
      }
      type_exec(v,FILE,,,"Del",bufa);

      break;
    case  35: //touch
      if (bav) type_exec(v,FILE,,,"Touch",bufa,"\"\""); //Update time & date
      else
       if (filenameOK(bufa)) FileWrite(bufa,NULL,0); //Create file
       else err_print(ERR_FILEI,"info");

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
      if (!bav) { err_print(ERR_NF,bufa); goto nocd; }
      if (type_got(v,FILE,,FALSE)) { err_print(ERR_FILEIDRVDIR,bufa); goto nocd; }
      
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
      Man(bufa);

      break;
    case  61: //pal
      if (fc)
        if (flag_err(a->flags,FLG_D,,help_file,err_cmd)) break;

      if (fc)
        PopUpColorDither;
      else
        PopUpColor;

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
        if (flag_err(a->flags,FLG_F,,help_file,err_cmd)) break;

      CPURep(fc);

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
      type_exec(v,FILE,,,"ExeFile",bufa);

      break;
    case 227: //mv
      if (type_got(v,DIR,,FALSE)) {
        shell_exec("CopyTree",,bufa,bufb);
        shell_exec("DelTree",,bufa);
      }
      else {
        if (type_got(v,DRV,,FALSE)) {
          err_print(ERR_DRVIDIRFILE,bufa);
          break;
        }
        shell_exec("Move",,bufa,bufb);
      }

      break;
    case 158: //date
      "%D\n",Now;

      break;
    case 169: //help
      if (!FileFind(help_file)) { err_print(ERR_NF,help_file); break; }

      if (bav) viewer(str_cat(bufe,,
                              "Type(\"",help_file,"\");"));
      break;
    case 174: //grep
      F(bufa);

      break;
    case 177: //time
      "%T\n",Now;

      break;
    case 179: //more
      type_exec(v,FILE,,,"More",bufa);

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
      else err_print(ERR_FILEI,bufa);

      break;
    case 203: //df
      DrvRep; "\n";
      drv_free;

      break;
    case 211: //cp
      if (fc) {
        if (flag_err(a->flags,FLG_D,,help_file,err_cmd)) break;
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
        if (flag_err(a->flags,FLG_T,,help_file,err_cmd)) break;

      bufe=StrNew(bufa);

      if (a->count==1) bufe=StrNew(".");

      if (a->count==2)
        if (str_cmp(bufa,"-")) bufe=StrNew(prev_dir);
      
      ls(bufe,(fc||idx==176));"\n";

      break;
    case 999:
    default:
      shell_exec("",TRUE,a->args[0]); //User is trying to normally run a OS command?
  }
  goto error;

nferror:
  err_print(ERR_NF,bufa);

error:
  zFree(bufe);
  return res;
}

U8 templeDOS() {
  Seed; I64 termID = AbsI64(RandI32);

//  Adam("\"\nBoot Time:%%7.3fs\n\n\",tS;");

//  Adam("\"$$LTCYAN$$TODO:$$FG$$ \n\n\";");

  Adam("\"templeDOS [%d]: started: %D %T\n\";",termID,Now,Now);

  set_windowinfo("templedos_task","TempleDOS");

  DocClear; DocMax;

//  "\n$FG,3$TempleDOS {Version 1.0}$FG$\n";
  "\nTempleDOS {Version 1.0}\n";
  "(c) 2024 No rights reserved. For Public Domain use.\n";
  "Type 'help' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";
//  "Type '$FG$$FG,2$help$FG$' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  U64 res=0;
  U8 *input=NULL;

  while (TRUE)
  {
    DocBottom;
    "\n%c:%s: ",(cur_drv),Fs->cur_dir; // Display prompt
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

SettingsPop;

