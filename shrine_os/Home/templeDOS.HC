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

#include "./shared.HC"


#define REC_CNT 31
U8 *VSAM[REC_CNT][8] =
{
/*ID, token count min, token count max,
file / dir validator, flag count min,
flag count max*/

{496,   "cd",   "~", 1, 2,  TRUE, 0, 0},
{502,   "df",    "", 1, 1, FALSE, 0, 0},
{504,   "ed",    "", 2, 2, FALSE, 0, 0},
{508,   "cp",   "d", 3, 3, FALSE, 0, 1},
{517,   "fm",   "f", 1, 3,  TRUE, 0, 1},
{547,   "ls",    "", 1, 2,  TRUE, 0, 0},
{554,   "mv",    "", 3, 3, FALSE, 0, 0},
{556,   "rd",    "", 2, 2,  TRUE, 0, 1},
{565,   "rm",    "", 2, 2,  TRUE, 0, 1},
{2084,  "cdd",  "~", 1, 2,  TRUE, 0, 0},
{2088,  "cat",   "", 2, 2,  TRUE, 0, 0},
{2149,  "cpu",  "f", 1, 1, FALSE, 0, 1},
{2242,  "man",   "", 2, 2, FALSE, 0, 0},
{2257,  "mem",   "", 1, 1, FALSE, 0, 0},
{2323,  "now",   "", 1, 1, FALSE, 0, 0},
{2402,  "run",   "", 2, 2,  TRUE, 0, 0},
{2440,  "vol",   "", 1, 1, FALSE, 0, 0},
{8517,  "date",  "", 1, 1, FALSE, 0, 0},
{8816,  "help",  "", 1, 1, FALSE, 0, 0},
{8820,  "dump",  "", 2, 2,  TRUE, 0, 0},
{8920,  "exit",  "", 1, 1, FALSE, 0, 0},
{8932,  "grep",  "", 2, 2, FALSE, 0, 0},
{9309,  "more",  "", 2, 2,  TRUE, 0, 0},
{9640,  "quit",  "", 1, 1, FALSE, 0, 0},
{9641,  "time",  "", 1, 1, FALSE, 0, 0},
{9753,  "tree", "f", 1, 3,  TRUE, 0, 1},
{9755,  "view",  "", 2, 2,  TRUE, 0, 0},
{34374, "clear", "", 1, 1, FALSE, 0, 0},
{36886, "mkdir", "", 2, 2, FALSE, 0, 0},
{38294, "rmdir", "", 2, 2,  TRUE, 0, 1},
{39172, "touch", "", 2, 2, FALSE, 0, 0}

};
I64 cur_IDX = -1;

I64 indexOf(U8 *cmd) {
  U64 i = 0,
      h = 0;

  h = HashCodeFor(cmd);

  for (;i<REC_CNT;i++) {
    if (VSAM[i][0] == h) {
      return i;
    }
  }

  return -1;
}

U8 *help_file = "~/templeDOS.DD"; //Right now, this path is "hard-coded"

#define SEG_CNT 256
#define SEG_LEN 256
U8 data[SEG_CNT][SEG_LEN];

U64 seg_beg = 0,
       segs = 0;

U8 seg_push(U8 *si, U8 delim=' ')
{//Push a segment into the data stack.
  if (StrLen(si) > 0) {
    U64 i = 0,
      pos = segs;

    while (si[0] != '\0' && si[0] != delim) {
      data[pos][i] = si[0];
      si++; i++;
    }
    if (i > 0) {
      data[pos][i] = '\0';
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

U0 seg_clean()
{
  MemSet(data, '\0', sizeof(U8)*SEG_CNT*SEG_LEN);

  segs = seg_beg = 0;
}

U64 seg_count(U8 *seg_buf, Bool count_segs=TRUE, U8 delim=32)
{//Count either data segments or occurrences of a specific delimeter.
  U64 l = StrLen(seg_buf);

  if (l == 0) return 0;

  U64 count = 0,
          i = 0;

  while (i < l) {
    if (seg_buf[i] == delim) count++;

    i++;
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

        if (x == -1) {
          if (ValidFiles("0",seg_peek(i))) {
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

Bool flag_eq(U8 *flag, Bool err_disp = TRUE)
{//Validate command flag?
  if (cur_IDX > -1) {
    if (!(VSAM[cur_IDX][2][0] == flag[1])) {
      if (err_disp)
        err_print(ERR_FLGI,flag);
      return FALSE;
    }
  }

  return TRUE;
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

  U64 at = seg_count(cmd),
       i = 0;

  U8 *orig_cmd = cmd;

  fc = seg_count(cmd,FALSE,'-');
  tc = at - fc;

  if (tc == 0) return 0;

  for (i=0; i < at; i++) {
    seg_trim(cmd,FALSE,TRUE);

    cmd = seg_push(cmd);
  }

  i = 0;

  U8 *buffer,
     *buffera,
     *bufferb,
     *bufferc;

  Bool tf = FALSE; //General use true/false flag.

  cur_IDX = indexOf(seg_peek);

   buffer = seg_peek;
  buffera = tern(at>1,seg_peek(1),'\0');
  bufferb = tern(at>2,seg_peek(2),'\0');
  bufferc = tern(at>3,seg_peek(3),'\0');

  if (cur_IDX > -1) {
  if (err_check(VSAM[cur_IDX][3],VSAM[cur_IDX][4],
                VSAM[cur_IDX][5],
                VSAM[cur_IDX][6],VSAM[cur_IDX][7])) {
    switch (cur_IDX) {
      case 0: //cd
      case 9: //cdd
        //TODO: 
        //      * In linux, you can do "cd -" and it'll take
        //        to the directory, you were previously in.
        Cd(tern(tc==2,buffera,"~"));

        if (cur_IDX == 9) shell_execute("Dir;");

        break;
      case 1: //df
        DrvRep; "\n";
        drv_free;

        break;
      case 2: //ed
        Ed(buffera);

        break;
      case 3: //cp
        buffer = tern(fc==1,bufferb,buffera);
        if (ValidFiles(,buffer)) {
          if (fc == 1) {
            if (flag_eq(buffera,TRUE)) { // "-d"
              CopyTree(buffer,bufferc);
            }
          }
          else {
            Copy(buffer,bufferb);
          }
        }
/*        else {
          "is_drv: %d\n",is_drv(buffer);

          err_print(tern(is_drv(buffer)<0,
                    ERR_FILENF,ERR_DRVIM),buffer);
        }*/

        break;
      case 4: //fm
      case 25: //tree
        if (fc == 1) {
          if (!(tf = flag_eq(buffera,TRUE))) { //-f
            goto done;
          }
        }

        buffer = tern(fc==0,buffera,bufferb);

        MiniFM(tern(tc == 1,".",buffer),,tf);

        break;
      case 5: //ls
        "\n";
        Dir(tern(tc==1,".",buffera));
        break;
      case 6: //mv
        if (i = ValidFiles("10",buffera,bufferb)) { //Don't allow override.
/*          if (IsDir(buffera)) {
            CopyTree(buffera,bufferb);
            DelTree(buffera);
          }
          else {
            Move(buffera,bufferb);
          }*/
        }
        else {
/*          buffer = tern(i==0,ERR_FILENF,ERR_FILEFF);
          err_print(buffer,tern(i==0,buffera,bufferb));*/
        }


        break;
      case 7: //rd
      case 8: //rm
      case 29: //rmdir
        if (fc == 1 || cur_IDX == 7 || cur_IDX == 29) {
          if (fc == 1) { //No short circuiting in this language is killing me.
            if (!flag_eq(buffera,TRUE)) { //-d
              goto done;
            }
          }

          buffer = tern(fc==0,buffera,bufferb);

          DelTree(buffer);
        }
        else {
          Del(buffera);
        }

        break;
      case 10: //cat
        Type(buffera);
        break;
      case 11: //cpu
        if (fc == 1) {
          if (!(tf = flag_eq(buffera,TRUE))) { //-f
            goto done;
          }
        }

        CPURep(tf);

        break;
      case 12: //man
        Man(buffera);

        break;
      case 13: //mem
        MemRep;

        break;
      case 14: //now
        CDateStruct ds;
        Date2Struct(&ds, Now + local_time_offset);

        "%03tZ %03tZ %03d %T\n",
        ds.day_of_week, "ST_DAYS_OF_WEEK",
        ds.mon-1, "ST_MONTHS",
        ds.day_of_week,
        Now;

        break;
      case 15: //run
        ExeFile(buffera);

        break;
      case 16: //vol
        "Volume in drive %c: has no label.\n",cur_drv;//Don't think drives have labels in this OS.
        "Volume Serial Number is %s\n",DrvSerialNum(cur_drv);

        break;
      case 17: //date
        "%D\n", Now;

        break;
      case 18: //help
        if (FileFind(help_file)) {
          More(help_file);
        }
        else {
          err_print(ERR_FILENF,help_file);
        }

        break;
      case 19: //dump
        Dump(buffera);

        break;
      case 20: //exit
        //Don't need to worrry about aborting.  OS reclaims
        //all the memory, when the window is closed
        //and what else is there to worrry about?
        Exit;

        break;
      case 21: //grep
        F(buffera);

        break;
      case 22: //more
        More(buffera);

        break;
      case 23: //quit
        return 1;

        break;
      case 24: //time
        "%T\n", Now;

        break;
      case 26: //view
        DocClear; DocTop;
        Type(seg_peek);
        "$$BK,1$$Press ESC to exit ...$$BK,0$$";
        View; DocBottom;
        PutChars(CH_CTRLY);

        break;
      case 27: //clear
        DocClear;
        break;
      case 28: //mkdir
        if (ValidFiles("0",buffera)) {
          DirMk(buffera);
        }
        else {
          err_print(ERR_FILEFF,"info");
        }

        break;
      case 30: //touch
        //OK ... Angry. I made an attrib command that lets you
        //set file attributes. But, the system ignores them.
        //I can set a file READONLY and still edit/delete it.
        //Verified on FAT32 and RedSea. Killing me. I'll further,
        //validate this and try to figure out if it's me or something.

        // Creates an empty file, if it doesn't exist.
        if (ValidFiles("0",buffera)) {
          // Off-hand, looks like Touch() doesn't create
          // files. I'll look more at it and touchfile().
          FileWrite(buffera,NULL,0);
        }
        else {
          Touch(buffera,""); //Updates the time & date.
        }

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

//Adam error displayed:
//$PT$$FG$$BG$  &LexWarn OptPass012 COCCompile PrsFun $FG,4$$BK,1$WARNING:$FG$$BK,0$ Assign U0 in fun 'templeDOS'.
//
//  I have not been able to figure out what cause this.
//  So, I tell Adam to clear itself.
U0 templeDOS() {
  DocClear;

  //Perhaps, I'll get rid of this:
  DocMax; //Force people to use an unlimited command buffer.
          //It's not really unlimited, see $LK,"max_entries",A="FF:::/Adam/DolDoc/DocTerm.HC,max_entries"$.

  "\n$FG,3$TempleDOS [Version 1.0]$FG$\n";
  "(c) 2022 No rights reserved. For Public Domain use.\n";
  "Type '$FG$$FG,2$help$FG$' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  U64 result = 0;
  U8 *input;

  while (TRUE)
  {
    seg_clean;

    DocBottom;

    "\n%c:%s: ",cur_drv,Fs->cur_dir; // Display prompt

    // Get user input
    input = seg_trim(GetStr(,,GSF_SHIFT_ESC_EXIT), FALSE, TRUE);

    if (StrLen(input) > 0) {
      result = execute_cmd(input);
    }

    MemSet(input, '\0', sizeof(U8)*StrLen(input));

    if (result) break;
  }

  Free(input);
}

SettingsPush;

MenuPush(
  "File {"
  "  Exit(,CH_SHIFT_ESC);"
  "}"
);

Adam("DocClear;");

//Adam("\"\nStarting templeDOS...\n\";");

templeDOS;

Free(VSAM);

SettingsPop;
