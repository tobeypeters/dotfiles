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
U8 *help_file="~/templeDOS.DD";

U8 *prev_dir=NULL;

U8 execute_cmd(U8 *cmd) {
  a->init(a);
  a->parse(a, cmd);

  if (a->count==0) goto error;

  I64 res,idx,v,fc;
  res=idx=v=fc=0;

  if ((idx=c->hashdx(c,a->args[0]))==-1)
  {
    //Switching drives DOS style?
    if (str_len(a->args[0])==2) {
      if (a->args[0][1]==':')
        if (drv_mounted(a->args[0])) Drv(a->args[0][0]);
        else err_print(ERR_DRVIU,"info");
      goto error;
    }

    //try to "shell" execute it
    idx=999; 
    goto switchit;
  }

  fc=flags_val(a->flags);
  fc=fc.u8[7];

  if (!(I64_between(a->count,c->data[idx][2],c->data[idx][3]))) {
    err_print(ERR_ARGC); goto error; }

  if (!(I64_between(fc,0,c->data[idx][4]))) {
    err_print(ERR_FLGC); goto error; }

  U8 *bufa, *bufb;
  bufa=bufb=NULL;
  a->next(a);bufa=StrNew(a->get_current(a));
  a->next(a);bufb=StrNew(a->get_current(a));

  v=files_valid(bufa,bufb);
  U64 bav=v.u8[0];

  bav=(bav|(a->count==1));

  switchit:  
  switch(idx)
  {
$PT$$FG$$BG$    case   7: //clear
      DocClear;
      break;
    case  23: //mkdir
      if (!bav) DirMk(bufa);
      else {
        if (type_got(v,DIR))
          err_print(ERR_DIR_EXISTS,bufa);
      }
      break;
    case  30: //rmdir
    case 214: //rd
    case 224: //rm
      if (!bav) { err_print(ERR_NF,bufa); break; }


      if (I64_IN(idx,30,214) || (idx==224&&fc))
      {
        if (idx==224)
          if (flag_err(a->flags,FLG_D)) break;
        type_exec(v,DIR,,,"DelTree",bufa);
        break;
      }
      type_exec(v,FILE,,,"Del",bufa);

      break;
    case  35: //touch
      if (bav)
        type_exec(v,FILE,,,"Touch",bufa,"\"\""); //Update time & date
      else
       if (filenameOK(bufa)) FileWrite(bufa,NULL,0); //Create file
       else err_print(ERR_FILEI,"info");
      break;
    case  38: //tasks
      TaskRep;
      break;
    case  43: //cdd
    case 199: //cd
      if (file_char(bufa)) Cd(prev_dir);
      else {
        if (bav) {
          if (type_got(v,DIR)) {
            Cd(bufa);
            if (idx==43) ls;
            prev_dir=StrNew(Fs->cur_dir);
          }
        }
        else err_print(ERR_NF,bufa);
      }

      break;
    case  56: //cat
      if (bav) type_exec(v,FILE,,,"Type",bufa);
      break;
    case  60: //man
      if (bav) if (type_got(v,FILE)) Man(bufa);
      break;
    case  63: //mem
      viewer("MemRep;\"\n\";
              MemPageRep;\"\n\";");
      break;
    case  72: //cpu
        CPURep(!flag_err(a->flags,FLG_F));
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
      if (bav) type_exec(v,FILE,,,"ExeFile",bufa);
      break;
    case 227: //mv
      if (!bav) err_print(ERR_NF,bufa);
      if (type_got(v,DIR)) {
        CopyTree(bufa,bufb);
        DelTree(bufa);
      }
      else Move(bufa,bufb);
      break;
    case 158: //date
      "%D\n",Now;
      break;
    case 169: //help
      if (bav) {
          viewer(str_cat(bufa,,"Type(\"",
                        help_file,"\");"));
      }
      else err_print(ERR_NF,help_file);
      break;
    case 174: //grep
      F(bufa);
      break;
    case 177: //time
      "%T\n",Now;
      break;
    case 179: //more
      if (!bav) { err_print(ERR_NF,bufa); break; }
      if (type_got(v,FILE)) More(bufa);
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
    case 187: //view
      break;
    case 201: //ed
      if (filenameOK(bufa)) PopUpEd(bufa);
      else err_print(ERR_FILEI,"info");
      break;
    case 203: //df
      DrvRep; "\n";
      drv_free;
      break;
    case 211: //cp
      if (bav)
      {
        if (!flag_err(a->flags,FLG_D)) {
          type_exec(v,DIR,,,"CopyTree",bufa,bufb);
        }
        else type_exec(v,FILE,,,"Copy",bufa,bufb);
      }
      else err_print(ERR_NF,bufa);
      break;
    case 212: //fm
      FileMgr;
      break;
    case 176: //tree
    case 223: //ls
      if (bav||((a->count==2)&&(fc==1))) {
        if (a->count==1) bufa=StrNew(".");
        ls(bufa,(idx==176||(!flag_err(a->flags,FLG_T,FALSE))));
      }
      break;
    case 999: //dummy
    default:
      shell_exec(a->args[0]); //User is trying to normally run a OS command?
      goto error;
  }

  str_zero(bufa);
  str_zero(bufb);
error:
  return res;
}

U8 templeDOS() {
  Seed; I64 termID = AbsI64(RandI32);

  Adam("DocClear;");

  Adam("\"\nBoot Time:%%7.3fs\n\",tS;");
  Adam("\"templeDOS [%d]: spawned : %D %T\n\";",termID,Now,Now);

  set_windowinfo("templedos_task","TempleDOS");

//  DocClear; DocMax;
  DocMax;

  "\n$FG,3$TempleDOS {Version 1.0}$FG$\n";
  "(c) 2024 No rights reserved. For Public Domain use.\n";
  "Type '$FG$$FG,2$help$FG$' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  U64 res=0;
  U8 *input=NULL;

  while (TRUE)
  {
    "\n%c:%s: $$PT$$",(cur_drv),Fs->cur_dir; // Display prompt
    input = GetStr(,,GSF_SHIFT_ESC_EXIT);

    res=execute_cmd(input);

    if (str_cmp(input,"exit")) break;

    str_zero(input,FALSE);
  }

  str_zero(input);

  Adam("\"templeDOS [%d]: terminated : %D %T\";",termID,Now,Now);

  return res; // 0: regular exit, 1: <shift>+<esc>
}

//U0 stop_ctrl_alt_x()
//{//Until Ifigure out how to trap it properly.
//  XTalk(Fs,"exit\n");
//}

SettingsPush;

MenuPush(
  "File {"
  "  Exit(,CH_SHIFT_ESC);"
  "}"
  "View {"
  "  PlainText(,CH_CTRLT);"
  "  Border(,CH_CTRLB);"
  "  FileMgr(,CH_CTRLD);"
  "}"
);


//Fs->task_end_cb=&stop_ctrl_alt_x;

Cd;prev_dir=StrNew(Fs->cur_dir);

templeDOS;

a->init(a);
Free(a);
Free(c);

Free(prev_dir);

DocBottom; "$$FG$$";

SettingsPop;

