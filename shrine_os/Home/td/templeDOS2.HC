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
  I64 res,idx,fc,v;
  idx=fc=v=res=0;

  a->init(a);
  a->parse(a, cmd);

  if (a->count==0) goto done;

  if (!(idx=c->hashdx(c,a->args[0])))
  {//try to "shell" execute it
    idx=999; 
    goto switchit;
  }

  fc=flags_val(a->flags);
  fc=fc.u8[7];

  "\nA->COUNT: %d ",a->count;
  //errors:
  //Tokens entered between min & max
  "ERR_ARGC_MAX: %d\n",c->data[idx][3];
  if (!(I64_between(a->count,c->data[idx][2],c->data[idx][3])))
  {
    err_print(ERR_ARGC);
  }
  
  ////Flags entered between 0 & max
  "A->FLAGS: %s FLAGS_COUNT: %d ",a->flags,fc;
  "ERR_FLGC_MAX: %d\n\n",c->data[idx][5];
  if (!(I64_between(fc,0,c->data[idx][5])))
  {
    err_print(ERR_FLGC);
  }

  U8 *bufa, *bufb;
  bufa=bufb=NULL;

  a->next(a);bufa=StrNew(a->get_current(a));
  a->next(a);bufb=StrNew(a->get_current(a));

  "BUFA: %s   BUFB: %s\n",bufa,bufb;

  v=files_valid(,bufa,bufb);
  "BUFAV: %d BUFAV: %d\n\n",v.u8[0],v.u8[1];

/*
HASH idx,
command,
token min,
token max,
validate file(s) / dir{s},
flag max */

/*  a->args[idx][0]
  a->args[idx][1]

  a->args[idx][2]
  a->args[idx][3]

  a->args[idx][4]

  a->args[idx][5]
*/
  switchit:  
  switch(idx)
  {
$PT$$FG$$BG$    case   7: //clear
      DocClear;
      break;
    case  23: //mkdir
      break;
    case  30: //rmdir
    case 214: //rd
      break;
    case 224: //rm
      break;
    case  35: //touch
      break;
    case  38: //tasks
      TaskRep;
      break;
    case  43: //cdd
    case 199: //cd
      //TODO: 
      //      * In linux, you can do "cd -" and it'll take
      //        to the directory, you were previously in.
      "%s\n",prev_dir;
      prev_dir=Fs->cur_dir;
      Cd(bufa);
      if (idx==199) ls;
      break;
    case  56: //cat
      Type(bufa);
      break;
    case  60: //man
      Man(bufa);
      break;
    case  63: //mem
        viewer("MemRep;\"\n\";
                MemPageRep;\"\n\";
               ");
      break;
    case  72: //cpu
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
      ExeFile(bufa);
      break;
    case 227: //mv
      break;
    case 158: //date
      "%D\n",Now;
      break;
    case 169: //help
      break;
    case 174: //grep
      F(bufa);
      break;
    case 177: //time
      "%T\n",Now;
      break;
    case 176: //tree
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
    case 187: //view
      break;
    case 201: //ed
      PopUpEd(bufa);
      break;
    case 203: //df
      DrvRep; "\n";
      drv_free;
      break;
    case 211: //cp
      break;
    case 212: //fm
      //We'll just call Terrys Filemanager
      break;
    case 223: //ls
      ls;
      break;
    case 999: //dummy
    default:
      "default\n";
  }

done:
  str_zero(bufa);
  str_zero(bufb);

  return res;
}

U8 templeDOS() {
  Seed; I64 termID = AbsI64(RandI32);

  Adam("DocClear;");

  Adam("\"\nBoot Time:%%7.3fs\n\",tS;");
  Adam("\"templeDOS [%d]: spawned : %D %T\n\";",termID,Now,Now);

  Adam("$$LTCYAN$$TODO:$$FG$$ Add the cd - support");

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
    "\n%c:%s: ",(cur_drv),Fs->cur_dir; // Display prompt
    input = GetStr(,,GSF_SHIFT_ESC_EXIT);

    res=execute_cmd(input);

    if (str_cmp(input,"exit")) break;

    str_zero(input,FALSE);
//    MemSet(input,'\0',sizeof(input));
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

Cd;
prev_dir=Fs->cur_dir;

templeDOS;

a->init(a);
Free(a);
Free(c);

//Free(prev_dir);

DocBottom; "$$FG$$";

SettingsPop;

