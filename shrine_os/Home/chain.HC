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

U8 chain_pop()
{//Pop a link, off the chain. Here we're not removing
 //anything from the chain. So, this is another big
 //difference from a normal stack.
 if (links > 0) {
   U8 *result = chain[begin];

   begin++;
   links--;

   return result;
 }

 return "";
}

U8 chain_peek(U64 idx)
{//Peek at a link on the chain.
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

//Yes, I'm handing error checking and validation HORRIBLY.
U0 err_print(U8 *msg, U8 *link="Usage")
{//Print our err_msg.
  "`[$FG,3$%s$FG$]`: %s ...\n", link, msg;
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
    U64 i = begin; //begin should be 1, from prev chain_pop

    while (i <= links) {
      //I don't use IsDir(), cause FileFind works
      //on 99% of directories. If you want to cd to the root,
      //It doesn't like 'cd /'. FileFind wants "cd ..";
      if ((StrLen(chain[i]) == 1) && chain[i][0] == 47) { // '/' check
        chain_push("..",i);
      }
          
      if (!FileFind(chain_peek(i))) {
        err_print("does not exist",chain[i]);
        return FALSE;
      }

      i++;
    }
  }

  return TRUE;
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

U8 execute_cmd(U8 *cmd) {
  U64 at = link_count(cmd),
       i = 0,
       h = 0;

  Bool tf = FALSE;

  fc = link_count(cmd,FALSE,'-');
  tc = at - fc;

  if (tc > 0) {
//    "\ntc [%d] fc [%d]\n\n",tc,fc;

    for (i=0; i < at; i++) {
      link_trim(cmd,FALSE,TRUE);

      cmd = chain_push(cmd);
    }

    h = HashCodeFor(chain_pop);
  }

//  "HashCodeFor [%d]\n", h;

// MemBIOSRep;
// Trace(ON); or Trace(OFF);

  if (h == 98262) { //cat
    if (err_check(2,2,TRUE)) {
      Type(chain_pop());
    }
  }
  else if (h == 3169 || h == 98339) { //cd & cdd
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

/*
tcmin=1
tcmax=1
existance_check=FALSE
fcmin=0
fcmax=0
*/


  else if (h == 94746189) { //clear
    if (err_check) {
      DocClear;
    }
  }
  else if (h == 3181) { //cp
    if (err_check(3,4,TRUE,,1)) {
      if (at == 3) {
        Copy(chain_pop, chain_pop);
      }
      else {
        if (flag_eq(chain_pop,1495)) { // "-d"
          CopyTree(chain_pop, chain_pop);
        }
      }
    }
  }

  else if (h == 98728) { //cpu
    if (err_check(,,,,1)) {
      if (fc == 1) {
        if (flag_eq(chain_pop,1497)) { //-f
          tf = TRUE;
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
    if (err_check(,2,,0,TRUE)) {
      Ed(chain_pop);
    }
  }
  else if (h == 3127582) { //exit
    if (err_check) {
      return 1;
    }
  }
  else if (h == 3271) { //fm
    if (err_check(,3,,1)) {
      Bool full_details = FALSE;

      if (fc == 1) {
        full_details = flag_eq(chain_pop,1497); //-f
      }

      MiniFM(chain_pop,,full_details); 
    }
  }
  else if (h == 3181270) { //grep
//    if (err_check(,2,,0)) {
//      F(tokens[1]);
//    }
  }
  else if (h == 3198785) { //help
//    if (ace = x == 1) {
//      U64 i;

//      "\n%-6s\tDescription\n", "Cmd";
//      "---------------------------\n";
//      for (i=0; i < CMD_LEN; i++) {
//        "$FG$$FG,2$%-6s $FG$\t%s\n", CMD_LIST[i][0], CMD_LIST[i][1];
//      }
//    }
  }
  else if (h == 3463) { //ls
//    if (ace = 0 < x < 3) {
//      "\n";
//      if (x == 2) {
//        Dir(tokens[1]);
//      } else {
//        Dir;
//      }
//    }
  }
  else if (h == 107866) { //man
//    if (ace = x == 2) {
//      Man(tokens[1]);
//    }
  }
  else if (h == 107989) { //mem
//    if (ace = x == 1) {
//      MemRep;
//    }
  }
  else if (h == 103950895) { //mkdir
//    if (ace = x == 2) {
//      DirMk(tokens[1]);
//    }
  }
  else if (h == 3497) { //mv
//    if (ace = x == 3) {
//      Move(tokens[1], tokens[2]);
//    }
  }
  else if (h == 109270) { //now
//    if (ace = x == 1) {
//      CDateStruct ds;
//      Date2Struct(&ds, Now + local_time_offset);

//      "%03tZ %03tZ %03d %T\n",
//      ds.day_of_week, "ST_DAYS_OF_WEEK",
//      ds.mon-1, "ST_MONTHS",
//      ds.day_of_week,
//      Now;
//    }
  }
  else if (h == 3643) { //rm
//    if (ace = (1 < x < 4)) {
//      if (x == 2) {
//        Del(tokens[1]);
//      }
//      else {
//        h = HashCodeFor(tokens[1]);

//        if (afe = h == 1495) { //"-d"
//          DelTree(tokens[2]);
//        }
//      }
//    }
  }
  else if (h == 3560141) { //time
//    if (ace = x == 1) {
//      "%T\n", Now;
//    }
  }
  else if (h == 110550847) { //touch
//    if (ace = x == 2) {
//      // Currently only creates an empty file, if
//      // it doesn't exist already.
//      if (!FileExists(tokens[1])) {
//        // Off-hand, looks like Touch() doesn't create
//        // files. I'll look more at it and touchfile().
//        FileWrite(tokens[1], NULL, 0);
//      }
//      else {
//        Touch(tokens[1],"");
//      }
//    }
  }
  else {
//    external(tokens[0]);
  }

  return 0;
}

U0 TempleDOS() {
//  DocClear;

  "\n$FG,3$TempleDOS [Version 1.0]$FG$\n";
  "(c) 2022 No rights reserved. For Public Domain use.\n";
  "Type '$FG$$FG,2$help$FG$' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  U8 *input;
  U64 result = 0;

  while (1)
  {
    chain_clean;

    "\n%s: ", Fs->cur_dir; // Display prompt

    // Get user input
    input = link_trim(GetStr(,,GSF_SHIFT_ESC_EXIT), FALSE, TRUE);

    if (StrLen(input) > 0) {
      result = execute_cmd(input);
    }

    MemSet(input, '\0', sizeof(U8)*StrLen(input));

    if (result) break;
  }
}

TempleDOS;
