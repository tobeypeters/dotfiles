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
#help_file "::/Home/templeDOS.DD"

//#include "./shared.HC"
#include "C:/Home/shared.HC"
 
#define REC_CNT 32
#define REC_OVR 11
#define REC_TOT REC_CNT+REC_OVR
U8 *VSAM[REC_TOT][7] =
{
/*
  Very poor implementation, of a hashtable.
  See how I waste memory & stuff.

  HASH, command, token min, token max,
  validate file(s) / dir{s}, flag min, flag max
*/
{  0,  "view", 2, 2,  TRUE, 0, 0},
{  1,   "man", 2, 2, FALSE, 0, 0},
{  2,      "", 0, 0, FALSE, 0, 0},
{  3,  "date", 1, 1, FALSE, 0, 0},
{  4,    "ls", 1, 2, FALSE, 0, 0},
{  5,      "", 0, 0, FALSE, 0, 0},
{  6,      "", 0, 0, FALSE, 0, 0},
{  7,      "", 0, 0, FALSE, 0, 0},
{  8,    "mv", 3, 3, FALSE, 0, 0},
{  9,      "", 0, 0, FALSE, 0, 0},
{ 10,      "", 0, 0, FALSE, 0, 0},
{ 11, "tasks", 1, 1, FALSE, 0, 0},
{ 12,    "cd", 1, 2,  TRUE, 0, 0},
{ 13,   "cpu", 1, 1, FALSE, 0, 1},
{ 14,    "ed", 2, 2, FALSE, 0, 0},
{ 15,    "df", 1, 1, FALSE, 0, 0},
{ 16,   "cdd", 1, 2,  TRUE, 0, 0},
{ 17,      "", 0, 0, FALSE, 0, 0},
{ 18,      "", 0, 0, FALSE, 0, 0},
{ 19,  "grep", 2, 2, FALSE, 0, 0},
{ 20,  "time", 1, 1, FALSE, 0, 0},
{ 21,  "tree", 1, 2,  TRUE, 0, 0},
{ 22,   "vol", 1, 1, FALSE, 0, 0},
{ 23,      "", 0, 0, FALSE, 0, 0},
{ 24,    "cp", 3, 3, FALSE, 0, 1},
{ 25,   "now", 1, 1, FALSE, 0, 0},
{ 26,   "run", 2, 2,  TRUE, 0, 0},
{ 27,    "rd", 2, 2,  TRUE, 0, 1},
{ 28, "mkdir", 2, 2, FALSE, 0, 0},
{ 29,   "cat", 2, 2,  TRUE, 0, 0},
{ 30,      "", 0, 0, FALSE, 0, 0},
{ 31,  "exit", 1, 1, FALSE, 0, 0},

{  3, "rmdir", 2, 2,  TRUE, 0, 1},
{  4,   "mem", 1, 1, FALSE, 0, 0},
{  4,    "rm", 2, 2,  TRUE, 0, 1},
{  8,  "quit", 1, 1, FALSE, 0, 0},
{  8, "touch", 2, 2, FALSE, 0, 0},
{ 12, "clear", 1, 1, FALSE, 0, 0},
{ 14,  "help", 1, 1, FALSE, 0, 0},
{ 24,    "fm", 1, 3,  TRUE, 0, 1},
{ 24,  "more", 2, 2,  TRUE, 0, 0},
{ 27,  "dump", 2, 2,  TRUE, 0, 0},
{ 29,  "term", 1, 1, FALSE, 0, 0}

};

I64 cur_IDX = -1;

I64 indexOf(U8 *cmd)
{
  U64 i = REC_CNT,
      h = hash_code_for(cmd);

  if (str_cmp(VSAM[h][1],cmd)) return h;

  for (;i<REC_TOT;i++) {
    if (str_cmp(VSAM[i][1],cmd)) return i;
  }
  return -1;
}

U8 *help_file = "~/templeDOS.DD";

U64 seg_beg = 0,
       segs = 0;

#define SEG_CNT 256
#define SEG_LEN 256
U8 data[SEG_CNT][SEG_LEN];
U0 data_clean()
{
  MemSet(data, '\0', sizeof(U8)*SEG_CNT*SEG_LEN);

  segs = seg_beg = 0;
}

U8 seg_push(U8 *si, U8 delim=' ')
{//Push a segment into the data stack.
  if (StrLen(si) > 0) {
    U64 i = 0;

    while (si[0] != '\0' && si[0] != delim) {
      data[segs][i] = si[0];
      si++; i++;
    }

    segs++;

    while (*si == delim) si++;
  }

  return si; //Updated pointer position.
}

U8 seg_peek(I64 idx=-1)
{//Peek at a segment from the data stack.
 if (idx >= SEG_CNT) return NULL;

 return data[tern(idx == -1, seg_beg, idx)];
}

U64 seg_count(U8 *seg_buf, Bool count_segs=TRUE, U8 delim=32)
{//Parse and count either the number of data segments or
 //occurrences of a specific delimeter.
  I64 q = StrLen(seg_buf)-1;

  if (q < 1) return 0;

  U64 count = 0;

  while (q > -1) {
    if (seg_buf[q] == delim) count++;
    q--;
  }

  return count + count_segs;
}


U0 seg_trim(U8 *seg, Bool left=TRUE, Bool both=FALSE)
{//Trims leading or trailing spaces from a data segment.
 //left = TRUE : left trim
 //left = FALSE : right trim
 //both = TRUE : left &right trim
  if (StrLen(seg) == 0) return;

  if (left || both) {
    StrUtil(seg, SUF_REM_LEADING);
  }

  if (!left || both) {
    StrUtil(seg, SUF_REM_TRAILING);
  }
}

U64 tc = 0,
    fc = 0;

//Yes, I'm handing error checking and validation HORRIBLY.
U0 err_print(U8 *msg, U8 *link="Usage")
{//Print our err_msg.
  "`$FG,3$%s$FG$`: %s ...\n", link, msg;
}

Bool err_check(U64 tcmin=1, U64 tcmax=1,
	       Bool fd_check=FALSE,
	       U64 fcmin=0, U64 fcmax=0)
{//Cheap error checker.
  if (tc < tcmin || tc > tcmax) {
    err_print(ERR_ARGC);
    return FALSE;
  }

  if (fc < fcmin || fc > fcmax) {
    err_print(ERR_FLGC);
    return FALSE;
  }

  //Make sure all files & directories exist and
  //any specified drives are mounted.
  if (fd_check && tc > 1) {
    I64 i = 1,
        x = -1;

    while (i < segs) {
      if (!(data[i][0] == '-')) {
        //Are we changing to another drive?
        x = is_drv(data[i]);
        if (x == 0 || x == -2) {
            err_print(ERR_DRVIM,data[i]);
            return FALSE;
        }
        else if (x == -1) {
          if (valid_files("0",seg_peek(i))) {
            err_print(ERR_FILENF,data[i]);
            return FALSE;
          }
        }
      }

      i++;
    }
  }

  return TRUE;
}

//Think, this is how Terry does it.  I'm looking at another
//implementation, which might be simpplier. Not sure.
//DefineLstLoad("ST_TEMPLEDOS_FLAGS","d\0f\0b\0");
//DefineLstLoad("ST_TEMPLEDOS_FLAGS","a\0b\0c\0d\0\e\0f\0");

DefineLstLoad("ST_TEMPLEDOS_FLAGS","a\0b\0c\0d\0e\0f\0g\0h\0i\0j\0k\0l\0m\0n\0o\0p\0q\0r\0s\0t\0u\0v\0w\0x\0y\0z\0");

U8 *defined_flags = Define("ST_TEMPLEDOS_FLAGS")$WW,1$;

#define FLG_A 0x0000001 //a
#define FLG_B 0x0000002 //b
#define FLG_C 0x0000004 //c
#define FLG_D 0x0000008 //d
#define FLG_E 0x0000010 //e
#define FLG_F 0x0000020 //f
#define FLG_G 0x0000040 //g
#define FLG_H 0x0000080 //h
#define FLG_I 0x0000100 //i
#define FLG_J 0x0000200 //j
#define FLG_K 0x0000400 //k
#define FLG_L 0x0000800 //l
#define FLG_M 0x0001000 //m
#define FLG_N 0x0002000 //n
#define FLG_O 0x0004000 //o
#define FLG_P 0x0008000 //p
#define FLG_Q 0x0010000 //q
#define FLG_R 0x0020000 //r
#define FLG_S 0x0040000 //s
#define FLG_T 0x0080000 //t
#define FLG_U 0x0100000 //u
#define FLG_V 0x0200000 //v
#define FLG_W 0x0400000 //w
#define FLG_X 0x0800000 //x
#define FLG_Y 0x1000000 //y
#define FLG_Z 0x2000000 //z

Bool got_flag(U8 *flag_got=NULL, I64 flag_want)
{//Validate command flag?
  //Make sure we had parsed atleast one flag
  //and we previously found a valid command.
  if (fc == 0 || cur_IDX < 0)  return FALSE;

  I64 f = 0;

  my_scanflags(&f,defined_flags,flag_got);


  return ToBool((f&flag_want));
}

U8 execute_cmd(U8 *cmd) {
//CallerRep;
//PassTrace;
//Trace;
//PCIRep;
//MemBIOSRep;
//MemPageRep;
//MemRep;
//ZipRep;
//ProfRep;
//HeapLogSizeRep;
//ATARep;
//DrvRep;
//TaskRep;
//UnusedSpaceRep; //Demo

//dump;
//DrvMap;


  I64 at = seg_count(cmd),
       i = 0;

  U8 *orig_cmd = cmd;

  fc = seg_count(cmd,FALSE,'-');

  if ((tc = at - fc) == 0) return 0;

  for (; i < at; i++) {
    seg_trim(cmd,FALSE,TRUE);

    cmd = seg_push(cmd);
  } i = 0;


  Bool tf = FALSE; //General use true/false flag.

  cur_IDX = indexOf(seg_peek);

  U8  *buffer = seg_peek,
     *buffera = tern(at>1,seg_peek(1),'\0'),
     *bufferb = tern(at>2,seg_peek(2),'\0'),
     *bufferc = tern(at>3,seg_peek(3),'\0');

  if (cur_IDX > -1) {
  if (err_check(VSAM[cur_IDX][2],VSAM[cur_IDX][3],
                VSAM[cur_IDX][4],
                VSAM[cur_IDX][5],VSAM[cur_IDX][6])) {
    switch (cur_IDX) {
      case 0: //view
        viewer(str_cat(buffer,,"Type(\"",
                      buffera,"\");"));

        break;
      case 1: //man
        Man(buffera);

        break;
      case 3: //date
        "%D\n", Now;

        break;
      case 4: //ls
        "\n"; ls(tern(tc==1,".",buffera));

        break;
      case 8: //mv
        if (valid_files("10",buffera,bufferb)) { //Don't allow override.
          if (IsDir(buffera)) {
            CopyTree(buffera,bufferb);
            DelTree(buffera);
          }
          else {
            Move(buffera,bufferb);
          }
        }

        break;
      case 11: //tasks
        TaskRep;

        break;
      case 12: //cd
      case 16: //cdd
        //TODO: 
        //      * In linux, you can do "cd -" and it'll take
        //        to the directory, you were previously in.

        //Change the Dir; to ls;

        Cd(buffera);

        if (cur_IDX == 16) shell_execute("Dir;");

        break;
      case 13: //cpu
        if (fc == 1) {
          if (!(tf = got_flag(buffera,FLG_F))) { //-f
            goto done;
          }
        }

        CPURep(tf);

        break;
      case 14: //ed
	PopUpEd(buffera);

        break;
      case 15: //df
        DrvRep; "\n";
        drv_free;

        break;
      case 19: //grep
        F(buffera);

        break;
      case 20: //time
        "%T\n",Now;

        break;
      case 39: //fm
      case 21: //tree
        "\n"; ls(tern(tc==1,".",buffera),TRUE);

        break;
      case 22: //vol
        //Don't think drives have labels in this OS.
        "Volume in drive %c: has no label.\n",cur_drv;
        "Volume Serial Number is %s\n",DrvSerialNum(cur_drv);

        break;
      case 24: //cp
        buffer = tern(fc==0,buffera,bufferb);

        if (valid_files(,buffer) || (buffer[StrLen(buffer)-1]=='*')) {
          tf = IsDir(buffer);

          if (got_flag(buffera,FLG_D)) { // "-d"
            if (tf) {
              CopyTree(buffer,bufferc);
              goto done;
            }
          }
          else {
            if (!tf) {
              Copy(buffer,bufferb);
              goto done;
            }
          }

          err_print(tern(tf,ERR_DIRIFILE,ERR_FILEIDIR),buffer);
        }

        break;
      case 25: //now
        "%D %T\n",
        Now, Now;

        break;
      case 26: //run
        ExeFile(buffera);

        break;
      case 27: //rd
      case 34: //rm
      case 32: //rmdir
        if (I64_IN(cur_IDX,27,32) ||
            (cur_IDX == 34 && fc == 1)) {
          if (!got_flag(buffera,FLG_D)) { //-d
            goto done;
          }

          DelTree(tern(fc==0,buffera,bufferb));
        }
        else {
          if (IsDir(buffera)) {
            err_print(ERR_DIRIFILE,buffera);
          }
          else {
            Del(buffera);
          }
        }

        break;
      case 28: //mkdir
        if (valid_files("0",buffera)) {
          DirMk(buffera);
        }
        else {
          err_print(ERR_FILEAF,"info");
        }

        break;
      case 29: //cat
        Type(buffera);

        break;
      case 31: //quit
      case 35: //exit
        // As far as I Know ... You don't can't be notified 
        // and respond to <shift>+<esc>.  I do have one idea,
        // and I'll update this section if Ifigure it out.
        //Don't need to worrry about aborting.  OS reclaims
        //all the memory, when the window is closed
        //and what else is there to worrry about?

        return 1;

        break;
      case 33: //mem
        viewer("MemRep;\"\n\";
                MemPageRep;\"\n\";
               ");

        break;
      case 36: //touch
        //OK ... Angry. I made an attrib command that lets you
        //set file attributes. But, the system ignores them.
        //I can set a file READONLY and still edit/delete it.
        //Verified on FAT32 and RedSea. Killing me. I'll further,
        //validate this and try to figure out if it's me or something.

        // Creates an empty file, if it doesn't exist.
        if (valid_files("0",buffera)) {
          // Off-hand, looks like Touch() doesn't create
          // files. I'll look more at it and touchfile().
          FileWrite(buffera,NULL,0);
        }
        else {
          Touch(buffera,""); //Updates the time & date.
        }

        break;
      case 37: //clear
        DocClear;

        break;
      case 38: //help
        if (FileFind(help_file)) {
          viewer(str_cat(buffer,,"Type(\"",
                        help_file,"\");"));
        }
        else {
          err_print(ERR_FILENF,help_file);
        }

        break;
      case 40: //more
        More(buffera);

        break;
      case 41: //dump
        Dump(buffera);

        break;
      case 42: //term
        User;

        break;
      default:
        break;
    }

  }}
  else {
    shell_execute(orig_cmd); //User is trying to normally run a OS command?
  }

done:
  return 0;
}

U8 templeDOS() {
  Seed; I64 termID = AbsI64(RandI32);

  Adam("DocClear;");

  Adam("\"\nBoot Time:%%7.3fs\n\",tS;");
  Adam("\"templeDOS [%d]: spawned : %D %T\n\";",termID,Now,Now);
//  Adam("\"\n$$LTBLUE$$TODO:$$FG$$ Trap <ctrl>+<alt>+x\n\n\";");

  set_windowinfo("templedos_task","TempleDOS");


  DocClear;

  //Perhaps, I'll get rid of this:
  DocMax; //Force people to use an unlimited command buffe`r.
          //It's not really unlimited, see $LK,"max_entries",A="FF:::/Adam/DolDoc/DocTerm.HC,max_entries"$.

  "\n$FG,3$TempleDOS [Version 1.0]$FG$\n";
  "(c) 2024 No rights reserved. For Public Domain use.\n";
  "Type '$FG$$FG,2$help$FG$' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

//  "term: %d\n",hash_code_for("term");

//  "tn: %s\n",Fs->task_name;
//  "tt: %s\n",Fs->task_title;

  U64 result = 0;
  U8 *input;

  while (TRUE)
  {
    data_clean;

    DocBottom;

//    "\n$$MA,T=\"%c\",LM=\"Dir;\"$$:%s: ",cur_drv,Fs->cur_dir;
    "\n%c:%s: ",cur_drv,Fs->cur_dir; // Display prompt

    // Get user input, If I keep the callback,
    // I could switch this back to just use GetStr();
    input = MyGetStr(GSF_SHIFT_ESC_EXIT);

    if (str_cmp(input,"-1"))
    {
      result = 2;
      goto done;  
    }

    if (StrLen(input) > 0)
    {
      seg_trim(input, FALSE, TRUE);


      DocBottom;


      result = execute_cmd(input);
    }

    MemSet(input, '\0', sizeof(U8)*StrLen(input));
    done:
     if (result) break;
  }

  Free(input);


  Adam("\"templeDOS [%d]: terminated : %D %T\";",termID,Now,Now);

  return result-1; // 0: regular exit, 1: <shift>+<esc>
}

U0 stop_ctrl_alt_x()
{//Until Ifigure out how to trap it properly.
  XTalk(Fs,"exit\n");
}

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


Fs->task_end_cb=&stop_ctrl_alt_x;

templeDOS;

DocBottom; "$$FG$$";

Free(VSAM);

SettingsPop;
