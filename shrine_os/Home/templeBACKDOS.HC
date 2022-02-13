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

#define HASH_CNT 31
U8 *hashes[HASH_CNT][8] =
{
/*ID, token count min, token count max,
file / dir validator, flag count min,
flag count max*/

{496,   "cd",    "~", 1, 2,  TRUE, 0, 0},
{502,   "df",     "", 1, 1, FALSE, 0, 0},
{504,   "ed",     "", 2, 2, FALSE, 0, 0},
{508,   "cp",   "-d", 3, 3,  TRUE, 0, 1},
{517,   "fm",   "-f", 1, 2,  TRUE, 0, 0},
{547,   "ls",     "", 1, 2,  TRUE, 0, 0},
{554,   "mv",     "", 3, 3, FALSE, 0, 0},
{556,   "rd",     "", 2, 2,  TRUE, 0, 1},
{565,   "rm",     "", 2, 2,  TRUE, 0, 1},
{2084,  "cdd",   "~", 1, 2,  TRUE, 0, 0},
{2088,  "cat",    "", 2, 2,  TRUE, 0, 0},
{2149,  "cpu",  "-f", 1, 1, FALSE, 0, 1},
{2242,  "man",    "", 2, 2, FALSE, 0, 0},
{2257,  "mem",    "", 1, 1, FALSE, 0, 0},
{2323,  "now",    "", 1, 1, FALSE, 0, 0},
{2402,  "run",    "", 2, 2,  TRUE, 0, 0},
{2440,  "vol",    "", 1, 1, FALSE, 0, 0},
{8517,  "date",   "", 1, 1, FALSE, 0, 0},
{8816,  "help",   "", 1, 1, FALSE, 0, 0},
{8820,  "dump",   "", 2, 2,  TRUE, 0, 0},
{8920,  "exit",   "", 1, 1, FALSE, 0, 0},
{8932,  "grep",   "", 2, 2, FALSE, 0, 0},
{9309,  "more",   "", 2, 2,  TRUE, 0, 0},
{9640,  "quit",   "", 1, 1, FALSE, 0, 0},
{9641,  "time",   "", 1, 1, FALSE, 0, 0},
{9753,  "tree", "-f", 1, 2,  TRUE, 0, 1},
{9755,  "view",   "", 2, 2,  TRUE, 0, 0},
{34374, "clear",  "", 1, 1, FALSE, 0, 0},
{36886, "mkdir",  "", 2, 2, FALSE, 0, 0},
{38294, "rmdir",  "", 2, 2,  TRUE, 0, 1},
{39172, "touch",  "", 2, 2, FALSE, 0, 0}

};
I64 cur_IDX = -1;

I64 indexOf(U8 *cmd) {
  U64 i = 0,
      h = 0;

  h = HashCodeFor(cmd);

  for (;i<HASH_CNT;i++) {
    if (hashes[i][0] == h) {
      return i;
    }
  }

  return -1;
}


/*#define HASH_CNT 33
U8 *hashes[HASH_CNT] = { "cat", "cd", "cdd", "clear", "cp", "cpu",
                         "-d", "-f", "date", "df", "dump", "ed", "exit",
                         "fm", "tree", "grep", "help", "ls", "man",
                         "mem", "mkdir", "more", "mv", "now", "quit",
                         "rm", "rd", "rmdir", "run", "time", "touch",
                         "view", "vol" };
*/

 U8 *help_file = "~/templeDOS.DD"; //Right now, this path is "hard-coded"

//I use this memory chain system, like a stack. Kinda ...
//One major difference, Ican pull from the either end.
//Doing a POP, ONLY, increments the begin pointer and 
//decrements the links count.
#define MAX_LINKS 256
#define LINK_LEN  256

U8 chain[MAX_LINKS][LINK_LEN];
U64 links = 0,
    begin = 0;

U64 tc = 0,
    fc = 0;

U8 chain_push(U8 *si, I64 link_num=-1, U8 delim=' ')
{//Push a value, into the memory chain.
  if (StrLen(si) > 0) {
    U64 i = 0,
      pos = links;

    //Another example, of why this really isn't a stack.
    //I allow you to replace values.
    if (link_num > -1) {
      pos = link_num;
      links--;
    }

    while (si[0] != '\0' && si[0] != delim) {
      chain[pos][i] = si[0];
      si++; i++;
    }
    if (i > 0) {
      chain[pos][i] = '\0';
    }

    links++;

    while (*si == delim) si++;
  }

  return si; //Return the updated pointer position.
}

U8 chain_pop(Bool rock_bottom=TRUE)
{//Pop a value, from the memory chain. We don't remove
  //anything from the chain. So, this is a big
  //difference from using a normal stack.
  if (links == 0) return NULL;

  U64 idx = begin;
 
  if (!rock_bottom) {
    idx = begin + links - 1;
  }

  U8 *result = tern(rock_bottom, chain[begin], chain[idx]);

  begin += rock_bottom;

  links--;

  return result;
}

U8 chain_peek(Bool rock_bottom=TRUE,I64 idx=-1)
{//Peek at a link on the chain.
 if (idx == -1) idx = begin;
 if (!rock_bottom) idx = begin + links - 1;

 return chain[idx];
}

U0 chain_clean()
{//Clear the memory chain.
  MemSet(chain, '\0', sizeof(U8)*MAX_LINKS*LINK_LEN);

  links = begin = 0;
}

U64 link_count(U8 *chain, Bool count_links=TRUE, U8 delim=32)
{//Count either links or occurrences of a specific delimeter.
  U64 l = StrLen(chain);

  if (l == 0) return 0;

  U64 i = 0,
  count = 0;

  while (i < l) {
    if (chain[i] == delim) {
      count++;
    }

    i++;
  }

  return count + count_links;
}

U0 link_trim(U8 *link, Bool left=TRUE, Bool both=FALSE)
{//Trims leading or trailing spaces from a link.
 //left = TRUE : left trim
 //left = FALSE : right trim
 //both = TRUE : left &right trim
  if (StrLen(link) == 0) return;

  if (left || both) {
    StrUtil(link, SUF_REM_LEADING);
  }

  if (!left || both) {
    StrUtil(link, SUF_REM_TRAILING);
  }
}

//Yes, I'm handing error checking and validation HORRIBLY.
U0 err_print(U8 *msg, U8 *link="Usage")
{//Print our err_msg.
  "`$FG,3$%s$FG$`: %s ...\n", link, msg;
}

Bool err_check(U64 tcmin=1, U64 tcmax=1,
	       Bool existance_check=FALSE,
	       U64 fcmin=0, U64 fcmax=0)
{//Cheap error checker.
  if (tc < tcmin || tc > tcmax) {
    err_print("Invalid number of arguments provided");
    return FALSE;
  }

  if (fc < fcmin || fc > fcmax) {
    err_print("Invalid number of options provided");
    return FALSE;
  }

  if (existance_check && tcmax > 1) //Added tcmax check. Probably not needed.
  {//Make sure all files & directories exist.
    U64 i = begin, //begin should already be 1.
        l = 0,
        h = 0;

    while (i <= links) {
      if (!(chain[i][0] == '-')) {
        l = StrLen(chain[i]);

        //Are we changing to another mounted drive?
        if (l == 2 && chain[i][1] == ':') {
          h = HashCodeFor(chain[i]);

          if (445<h<547 || 317<h<419) { //a:..z: or A:..Z:
            if (!drv_valid(chain[i][0])) {
              goto drv_error;
            }
            goto drv_change;
          }
          else {
            goto drv_error;
          }

          drv_error:
            err_print("invalid drive specified or drive is currently not mounted",chain[i]);
            return FALSE;

          goto drv_change;
        }

        if (l == 1 && chain[i][0] == 47) { //FileFInd doesn't "/"
        }
        else {
          if (!FileFind(chain_peek(,i))) {
            err_print("does not exist",chain[i]);
            return FALSE;
          }
        }
        drv_change:
      }

      i++;
    }
  }

  return TRUE;
}

U0 shell_execute(U8 *cmd)
{//Execute a templeOS shell command.
  "\n"; ExePutS(cmd); "\n";
}

Bool flag_eq(U8 *flag, Bool err_disp = TRUE)
{//Flag is equal to *flag ...
  if (cur_IDX > -1) {
    if (!(hashes[cur_IDX][2] == flag)) {
      if (err_disp) {
        err_print("Invalid option provided",flag);
      }
      return FALSE;
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

  U64 at = link_count(cmd),
       i = 0;

  fc = link_count(cmd,FALSE,'-');
  tc = at - fc;

  if (tc > 0) {
    for (i=0; i < at; i++) {
      link_trim(cmd,FALSE,TRUE);

      cmd = chain_push(cmd);
    }
  }
  else {
    return 0;
  }

  U8 *orig_cmd = cmd,
       *buffer = '\0',
     *buffera,
     *bufferb,
     *bufferc;

  U64 h = 0;

  Bool tf = FALSE; //General use true/false flag.

  //I'm using pre-calculated hash codes, for comparison checks.
  //My opinion ... This is faster and better, than using 100
  // StrCmp() calls.

  //Guess, readability is destroyed.

  //NOTE:
  //Seems like HolyC evals right to left ...
  //Sometimes or always?
  //
  //For example:  [stra,strb]
  //             "Example strings: [%s,%s]\n",chain_pop,chain_pop;
  //
  //    I'd get:  Example strings: [strb,stra]
  // Instead of:  Example strings: [stra,strb]
  //
  //I'll look at it more.  Pretty sure, it's not my code.

  cur_IDX = indexOf(chain_pop);

  buffera = tern(at>1,chain_peek(,1),'\0');
  bufferb = tern(at>2,chain_peek(,2),'\0');
  bufferc = tern(at>3,chain_peek(,3),'\0');

  if (cur_IDX > 0) {
  if (err_check(hashes[3],hashes[4],hashes[5],
                hashes[6],hashes[7])) {
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
        if (fc == 1) {
          if (flag_eq(buffera,280)) { // "-d"
            CopyTree(bufferb,bufferc);
          }
        }
        else {
          Copy(buffera,bufferb);
        }

        break;
      case 4: //fm
      case 25: //tree
        if (fc == 1) {
          if (!(tf = flag_eq(buffera,282))) { //-f
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
        if (FileFind(buffera)) { //It's a file or dir.
          if (FileFind(bufferb))
          { //File or dir already exists.
            //I don't allow overriding now.
            err_print("Already exists",bufferb);
          }
          else {
            if (IsDir(buffera)) {
              CopyTree(buffera,bufferb);
              DelTree(buffera);
            }
            else {
              Move(buffera,bufferb);
            }
          }
        }
        else {
          err_print("Doesn't exist",buffera);        
        }

        break;
      case 7: //rd
      case 8: //rm
      case 29: //rmdir
        if (fc == 1 || cur_IDX == 7 || cur_IDX == 29) {
          if (fc == 1) { //No short circuiting in this language is killing me.
            if (!flag_eq(buffera,280)) { //-d
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
          if (!(tf = flag_eq(buffera,282))) { //-f
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
          err_print("File not found",help_file);
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
        Type(chain_peek);
        "$$BK,1$$Press ESC to exit ...$$BK,0$$";
        View; DocBottom;
        PutChars(CH_CTRLY);

        break;
      case 27: //clear
        DocClear;
        break;
      case 28: //mkdir
        if (!FileFind(buffera)) {
          DirMk(buffera);
        }
        else {
          err_print("Directory already exists","info");
        }

        break;
      case 30: //touch
        //OK ... Angry. I made an attrib command that lets you
        //set file attributes. But, the system ignores them.
        //I can set a file READONLY and still edit/delete it.
        //Verified on FAT32 and RedSea. Killing me.

        // Creates an empty file, if it doesn't exist.
        if (!FileFind(buffera)) {
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
//  Free(orig_cmd);
//  Free(buffer);
//  Free(buffera);
//  Free(bufferb);
//  Free(bufferc);

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

  //"HashCodeFor(\"dump\") %d\n",HashCodeFor("dump");

  while (TRUE)
  {
    chain_clean;

    DocBottom;

    "\n%c:%s: ",cur_drv,Fs->cur_dir; // Display prompt

    // Get user input
    input = link_trim(GetStr(,,GSF_SHIFT_ESC_EXIT), FALSE, TRUE);

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

Free(hashes);

SettingsPop;
