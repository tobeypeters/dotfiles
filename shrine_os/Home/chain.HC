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

U8 *help_file = "~/templeDOS.DD"; //Right now, this path is "hard-coded"

//I use this chain system, like a stack. Kinda ...
//But, one major difference, Ipull from the bottom.
//Also, really, in the future ... might as well remove
//the popping logic.  All I'm really doing is incrementing
//a number, which tells us where the start of the chain is.
#define MAX_LINKS 256
#define LINK_LEN  256

U8 chain[MAX_LINKS][LINK_LEN];
U64 links = 0,
    begin = 0;

U64 tc = 0,
    fc = 0;

U8 ternary(Bool condition, U8 *first, U8 *second) {
  if (condition) return first;

  return second;
}

U64 chain_push(U8 *si, I64 link_num=-1, U8 delim = ' ')
{//Weld a link, onto the chain.
  U64 i = 0,
    pos = links;

  //Another example, of why this really a stack.
  //I need to replace values.
  if (link_num > -1) {
    pos = link_num;
    links--;
  }

  while (si[0] != '\0' && si[0] != delim) {
    chain[pos][i] = si[0];
    si++; i++;
  }
  if (i > 0) chain[pos][i] = '\0';

  links++;  

  while (*si == delim) si++;

  return si;
}

U8 chain_pop(Bool rock_bottom=TRUE)
{//Pop a link, off the chain. Here we're not removing
 //anything from the chain. So, this is another big
 //difference from a normal stack.
 if (links > 0) {
   U64 idx = begin;

   if (!rock_bottom) {


   /* We're making the chain bi-directional. 

      * You can take links, from the begining and end.
      * You can't go pass the "beginning" link.
      * Ater, the "beginning" link is grabbed, links
        should be getting set to 0.

      EVERYTHING NEEDS TESTED. BUT, SHOULD WORK FINE.

      0 1 2
     [a|b|c] <- 3 elements
      ^ ^
      | |                  
      ------ : begin = 0 : elements - (begin == 0) = <--- 2
        |
        ---- : begin = 1 : elements - (begin == 0) = <--- 2

    */

     "links %d - (begin == 0) %d\n",links,(begin == 0);
     idx = links - (begin == 0);
   }

   "\n\n";
   "idx %d\n",idx;

   "rock_bottom %d\n",rock_bottom;
   "begin %d links %d\n",begin,links;
   U8 *result = ternary(rock_bottom, chain[begin], chain[idx]);
   
   begin += rock_bottom;

   "result %s\n",result;

   links--;
   "begin %d links %d\n",begin,links;

   return result;
 }

 return "";
}

 U8 chain_peek(I64 idx=-1)
{//Peek at a link on the chain.
 if (idx == -1) idx = begin;

 if (idx <= links) {
   return chain[idx];
 }

 return "";
}

U0 chain_clean()
{//Clear the chain.
  MemSet(chain, '\0', sizeof(U8)*MAX_LINKS*LINK_LEN);

  links = begin = 0;
}

U64 link_count(U8 *in_chain, Bool count_links = TRUE, U8 delim = ' ')
{//Count either links or occurrences of a specific delimeter,
 //for example, from our user input.
  U64 l = StrLen(in_chain);

  if (l == 0) return 0;

  U64 i = 0,
  count = 0;

  while (i < l) {
    if (in_chain[i] == delim) {
      count++;
    }

    i++;
  }

  return count + count_links;
}

U0 link_trim(U8 *link, Bool left = TRUE, Bool both = FALSE)
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
  U64 g = 31,
      i = 0,
   hash = 0;
 
  for (; i < StrLen(str); i++) {
    hash = g * hash + str[i];
  }

  return hash;
}

Bool drv_valid(U8 *drv)
{//Valid mounted drive?
  //I cannot find any built-in functions,
  //which didn't throw exceptions if I tested
  //for a unmounted/non existant drive ... like 'z:'
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
  if ((tc < tcmin || tc > tcmax) ||
      (fc < fcmin || fc > fcmax)) {
    err_print("Invalid number of arguments provided");
    return FALSE;
  }

  if (existance_check) {//Make sure all files & directories exist.
    U64 i = begin, //begin should be 1, from prev chain_pop.
        l = 0,
        h = 0;

    while (i <= links) {
      if (!(chain[i][0] == '-')) {
        l = StrLen(chain[i]);

        //Are we changing to another mounted drive?
        if (l == 2 && chain[i][1] == ':') { 
          h = HashCodeFor(chain[i]);

          if (3064<h<3841 || 2072<h<2849) { //a:..z: or A:..Z:
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
          if (!FileFind(chain_peek(i))) {
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

U0 external(U8 *cmd) {
  "\n"; ExePutS(cmd);
}

Bool flag_eq(U8 *flag, U64 eq, Bool err_disp = TRUE)
{
  if (!(HashCodeFor(flag) == eq)) {
    if (err_disp) {
      err_print("Invalid flag provided",flag);
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

  U8 *orig_cmd = cmd,
       *buffer = ""; //General purpose buffer.
     

  Bool tf = FALSE; //Scratch flag I can use for true/false.

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

  //"HashCodeFor [%d]\n", HashCodeFor("a:");

  //TODO:
  // MemBIOSRep;
  // Trace(ON); or Trace(OFF);
  // StkRep;

  //NOTE:
  //I don't think, it's anything I'm doing.
  //Seems like HolyC evals right to left.
  //I don't know if eval is the correct term.
  //
  //For example:
  //             I want : Copy(file1, file2);
  //             I do   : Copy(chain_pop, chain_pop);
  //             I get  : Copy(file2, file1);

  if (h == 98262) { //cat
    if (err_check(2,2,TRUE)) {
      "\n"; Type(chain_pop());
    }
  }
  else if (h == 3169 || h == 98339) { //cd & cdd
    //TODO: Add -m to allow cd to make directories,
    //      if they don't exist.
    if (err_check(,2,TRUE)) {
      if (tc == 2) {
        Cd(chain_pop);
      }
      else {
        Cd;
      }

      if (h == 98339) {
        external("Dir;");
      }
    }
  }
  else if (h == 94746189) { //clear
    if (err_check) {
      DocClear;
    }
  }
  else if (h == 3181) { //cp
    if (err_check(3,4,TRUE,,1)) {
      if (at == 3) {
        "Copy(%s,%s)\n",chain_pop,chain_pop(FALSE);
//        Copy(chain_pop, chain_pop(FALSE));
      }
      else {
        if (flag_eq(chain_pop,1495)) { // "-d"
          "CopyTree(%s,%s)\n",chain_pop,chain_pop(FALSE);
//          "CopyTree(%s,%s)\n",chain_pop,chain_pop(FALSE);
//          CopyTree(chain_pop, chain_pop(FALSE));
        }
      }
    }
  }
  else if (h == 98728) { //cpu
    if (err_check(,,,,1)) {
      if (fc == 1) {
        if (tf = flag_eq(chain_pop,1497)) { //-f
        }
        else {
          return 0;
        }
      }

      CPURep(tf);
    }
  }
  else if (h == 3076014) { //date
    if (err_check) {
      "%D\n", Now;
    }
  }
  else if (h == 3202) { //df
    if (err_check) {
      DrvRep;
    }
  }
  else if (h == 3231) { //ed
    if (err_check(,2,TRUE)) {
      Ed(chain_pop);
    }
  }
  else if (h == 3127582) { //exit
    if (err_check) {
      return 1;
    }
  }
  else if (h == 3271 || h == 3568542) { //fm & tree
    if (err_check(,3,TRUE,,1)) {
      if (fc == 1) {
        if (tf = flag_eq(chain_pop,1497)) { //-f
        }
        else {
          return 0;
        }
      }

      MiniFM(ternary(tc == 1,".",chain_peek),,tf);
    }
  }
  else if (h == 3181270) { //grep
    if (err_check(2,2,TRUE)) {
      F(chain_pop);
    }
  }
  else if (h == 3198785) { //help
    if (err_check) {
      if (FileFind(help_file)) {
        Type(help_file);
      }
      else {
        err_print("File not found",help_file);
      }
    }
  }
  else if (h == 3463) { //ls
    if (err_check(,2,TRUE)) {
      "\n";

      Dir(ternary(tc == 1,".",chain_peek));
    }
  }
  else if (h == 107866) { //man
    if (err_check(2,2)) {
      Man(chain_pop);
    }
  }
  else if (h == 107989) { //mem
    if (err_check) {
      MemRep;
    }
  }
  else if (h == 103950895) { //mkdir
    if (err_check(2,2)) {
      //TODO: Add an already exists check.

      if (DirMk(chain_pop)) {
      }
      else {
        buffer = ternary(FileFind(chain_peek),
                         "Directory already exists",
                         "Unable to create directory");

        err_print(buffer,chain_pop);
      }
    }
  }
  else if (h == 3497) { //mv
      if (err_check(3,3,TRUE)) {
        Move(chain_pop, chain_pop);
      }
  }
  else if (h == 109270) { //now
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
  else if (h == 3643) { //rm
    if (err_check(2,3,TRUE,,1)) {
      if (fc == 1) {
        if (tf = flag_eq(chain_pop,1495)) { //-d
        }
        else {
          return 0;
        }
      }

      if (at == 2) {
        Del(chain_pop);
      }
      else {
        DelTree(chain_pop);
      }
    }
  }
  else if (h == 3560141) { //time
    if (err_check) {
      "%T\n", Now;
    }
  }
  else if (h == 110550847) { //touch
    if (err_check(2,2)) {
      // Currently only creates an empty file, if
      // it doesn't exist already.
      if (!FileFind(chain_peek)) {
        // Off-hand, looks like Touch() doesn't create
        // files. I'll look more at it and touchfile().
        FileWrite(chain_pop, NULL, 0);
      }
      else {
        Touch(chain_pop,"");
      }
    }
  }
  else if (h == 116947) { //vol
    "Volume in drive %c: has no label.\n",cur_drv;//Don't think drives have labels in this OS.
    "Volume Serial Number is %s\n",DrvSerialNum(cur_drv);
  }
  else {
    external(orig_cmd); //User is trying to normally run a OS command?
  }

  return 0;
}

U0 TempleDOS() {
  DocClear;

  //Perhaps, I'll get rid of this:
  DocMax; //Force people to use an unlimited command buffer.
          //It's not really unlimited, see $LK,"max_entries",A="FF:::/Adam/DolDoc/DocTerm.HC,max_entries"$.

  "\n$FG,3$TempleDOS [Version 1.0]$FG$\n";
  "(c) 2022 No rights reserved. For Public Domain use.\n";
  "Type '$FG$$FG,2$help$FG$' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  U8 *input;
  U64 result = 0;

  while (1)
  {
    chain_clean;

    "\n%c:%s> ",cur_drv,Fs->cur_dir; // Display prompt

    // Get user input
    input = link_trim(GetStr(,,GSF_SHIFT_ESC_EXIT), FALSE, TRUE);

    if (StrLen(input) > 0) {
      result = execute_cmd(input);
    }

    MemSet(input, '\0', sizeof(U8)*StrLen(input));

    if (result) break;
  }
}

//Adam("\"\nStarting templeDOS...\n\";");

TempleDOS;
