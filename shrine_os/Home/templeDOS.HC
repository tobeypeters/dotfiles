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

/*#define HASH_CNT 32
U8 *hashes[HASH_CNT] = { "cat", "cd", "cdd", "clear", "cp", "cpu",
                         "-d", "-f", "date", "df", "ed", "exit",
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

U8 tern(Bool condition, U64 *first, U64 *second) {
  if (condition) return first;

  return second;
}

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

U64 HashCodeFor(U8 *str)
{//Hash code generator for strings.
 //This is a pretty weak one. I don't need much.
 //CRC16 would've been perfect for me. But, you
 //have to use big lookup table.
  U64 i = 0,
//  U64 g = 31, //Magic generator <- odd prime
   hash = 0;

  for (; i < StrLen(str); i++) {
    hash =  (hash << 2) + str[i];
//    hash =  ((hash << 5) - hash) + str[i]; //hash = g * hash + str[i];
  }

  return hash;
}

Bool drv_valid(U8 *drv)
{//Valid mounted drive?
 //I cannot find any built-in functions, which didn't
 //throw exceptions if I tested a unmounted / non 
 //existent drive ... like 'z:'
  CDrv *dv;
  CBlkDev *bd;

  I64 i,drv_let;

  drv = ToUpper(drv);

  for (i=0,dv=blkdev.drvs;i<DRVS_NUM;i++,dv++) {
    if (dv->dv_signature==DRV_SIGNATURE_VAL) {
      bd=dv->bd;
      drv_let=Drv2Let(dv);
      if (drv_let == drv) {
        return TRUE;
      }
    }
  }

  return FALSE;
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

Bool flag_eq(U8 *flag, U64 eq, Bool err_disp = TRUE)
{//Validate a flag.
  if (!(HashCodeFor(flag) == eq)) {
    if (err_disp) {
      err_print("Invalid option provided",flag);
    }

    return FALSE;
  }

  return TRUE;
}

U8 cur_drv()
{//Return the current drive letter.
  return Drv2Let(Fs->cur_dv);
}

U8 execute_cmd(U8 *cmd) {
  U64 at = link_count(cmd),
       i = 0;

  fc = link_count(cmd,FALSE,'-');
  tc = at - fc;

  U8 *orig_cmd = cmd,
       *buffer = "";
  
  U8 *buffera = '\0',
     *bufferb = '\0',
     *bufferc = '\0';

  if (tc > 0) {
    for (i=0; i < at; i++) {
      link_trim(cmd,FALSE,TRUE);

      cmd = chain_push(cmd);
    }
  }
  else {
    return 0;
  }

  U64 h = 0;

  Bool tf = FALSE; //General use true/false flag.

  //Switch seems broke.
  //  switch (h) {
  //    case 0:
  //      "one\n";
  //      break;
  //    case 99998:
  //      "two\n";
  //      break;
  //    default:
  //  }

  //I'm using pre-calculated hash codes, for comparison.
  //My opinion ... This is faster and better, than
  //using 100 StrCmp() calls.
  h = HashCodeFor(chain_pop);

  /*for (i=0;i < HASH_CNT; i++) {
    "%s %d\n",hashes[i],HashCodeFor(hashes[i]);
  }*/

  //"HashCodeFor [%d]\n", HashCodeFor("a:");

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

  if (at > 1) buffera = chain_peek(,1);
  if (at > 2) bufferb = chain_peek(,2);
  if (at > 3) bufferc = chain_peek(,3);

  if (h == 2088) { //cat
    if (err_check(2,2,TRUE)) Type(buffera);
  }
  else if (h == 496 || h == 2084) { //cd, cdd
    //TODO: 
    //      * In linux, you can do "cd -" and it'll take
    //        to the directory, you were previously in.
    if (err_check(,2,TRUE)) {
      Cd(tern(tc==2,buffera,"~"));

      if (h == 2084) shell_execute("Dir;");
    }
  }
  else if (h == 34374) { //clear
    if (err_check) DocClear;
  }
  else if (h == 508) { //cp
    if (err_check(3,3,TRUE,,1)) {
      if (fc == 1) {
        if (flag_eq(buffera,280)) { // "-d"
          CopyTree(bufferb,bufferc);
        }
      }
      else {
        Copy(buffera,bufferb);
      }
    }
  }
  else if (h == 2149) { //cpu
    if (err_check(,,,,1)) {
      if (fc == 1) {
        if (!(tf = flag_eq(buffera,282))) { //-f
          return 0;
        }
      }

      CPURep(tf);
    }
  }
  else if (h == 8517) { //date
    if (err_check) "%D\n", Now;
  }
  else if (h == 502) { //df
    if (err_check) DrvRep;
  }
  else if (h == 504) { //ed
    if (err_check(2,2)) Ed(buffera);
  }
  else if (h == 8920) { //exit
    //Don't need to worrry about aborting.  OS reclaims
    //all the memory, when the window is closed
    //and what else is there to worrry about?
    if (err_check) Exit;
  }
  else if (h == 517 || h == 9753) { //fm, tree
    if (err_check(,2,TRUE,,1)) {
      if (fc == 1) {
        if (!(tf = flag_eq(buffera,282))) { //-f
          return 0;
        }
      }

      buffer = tern(fc==0,buffera,bufferb);

      MiniFM(tern(tc == 1,".",buffer),,tf);
    }
  }
  else if (h == 8932) { //grep
    if (err_check(2,2)) F(buffera);
  }
  else if (h == 8816) { //help
    if (err_check) {
      if (FileFind(help_file)) {
        More(help_file);
      }
      else {
        err_print("File not found",help_file);
      }
    }
  }
  else if (h == 547) { //ls
    if (err_check(,2,TRUE)) {
      "\n";
      Dir(tern(tc==1,".",buffera));
    }
  }
  else if (h == 2242) { //man
    if (err_check(2,2)) Man(buffera);
  }
  else if (h == 2257) { //mem
    if (err_check) MemRep;
  }
  else if (h == 36886 || h == 536) { //mkdir
    if (err_check(2,2)) {
      if (!FileFind(buffera)) {
        DirMk(buffera);
      }
      else {
        err_print("Directory already exists","info");
      }
    }
  }
  else if (h == 9309) { //more
    if (err_check(2,2,TRUE)) More(buffera);
  }
  else if (h == 554) { //mv
    if (err_check(3,3)) {
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
    }
  }
  else if (h == 2323) { //now
    if (err_check) {
      CDateStruct ds;
      Date2Struct(&ds, Now + local_time_offset);

      "%03tZ %03tZ %03d %T\n",
      ds.day_of_week, "ST_DAYS_OF_WEEK",
      ds.mon-1, "ST_MONTHS",
      ds.day_of_week,
      Now;
    }
  }
  else if (h == 9640) { //quit
    if (err_check) return 1;
  }
  else if ((h == 565) || h == 556 || h == 38294) { //rm, rd, rmdir
    if (err_check(2,2,TRUE,,1)) {
      if (fc == 1 || h == 556 || h == 38294) {
        if (fc == 1) { //No short circuiting in this language is killing me.
          if (!flag_eq(buffera,280)) { //-d
            return 0;
          }
        }

        buffer = tern(fc==0,buffera,bufferb);

        DelTree(buffer);
      }
      else {
        Del(buffera);
      }
    }
  }
  else if (h == 2402) { //run
    if (err_check(2,2,TRUE)) ExeFile(buffera);
  }
  else if (h == 9641) { //time
    if (err_check) "%T\n", Now;
  }
  else if (h == 39172) { //touch
    if (err_check(2,2)) {
      // Creates an empty file, if it doesn't exist.
      if (!FileFind(buffera)) {
        // Off-hand, looks like Touch() doesn't create
        // files. I'll look more at it and touchfile().
        FileWrite(buffera,NULL,0);
      }
      else {
        Touch(buffera,""); //Updates the time & date.
      }
    }
  }
  else if (h == 9755) { //view
    if (err_check(2,2,TRUE)) {
      DocClear; DocTop;
      Type(chain_peek);
      "$$BK,1$$Press ESC to exit ...$$BK,0$$";
      View; DocBottom;
      PutChars(CH_CTRLY);
    }
  }
  else if (h == 2440) { //vol
    if (err_check) {
      "Volume in drive %c: has no label.\n",cur_drv;//Don't think drives have labels in this OS.
      "Volume Serial Number is %s\n",DrvSerialNum(cur_drv);
    }
  }
  else {
    shell_execute(orig_cmd); //User is trying to normally run a OS command?
  }

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

  //"HashCodeFor(\"exit\") %d\n",HashCodeFor("exit");

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

SettingsPop;
