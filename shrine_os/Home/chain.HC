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
               U64 fcmin=0, U64 fcmax=1,
               Bool existance_check=FALSE, Bool flag_check=FALSE)
{//Cheap error checker.
  if ((tc < tcmin || tc > tcmax) ||
      (fc < fcmin || fc > fcmax)) {
    err_print("Invalid number of arguments provided");
    return FALSE;
  }

  //INCORRECT way to do this. This DEFINITELY
  //restricts the flags you can have to one.
  if (flag_check) {
/*    U64 i = 0,
        h = 0,
    flagc = 2;

    Bool found = FALSE;

    h = HashCodeFor(chain_peek{begin));

    while (i < flagc) {
      if (h = 1495) found = TRUE; //-d
      if (h = 1497) found = TRUE; //-f
      i++;
    }

    if (!found) {
      
      return FALSE;
    }


    U64 i = begin; //begin should be 1, from prev chain_pop

    while (i <= links) {
      if (
      i++;
    }


    chain_pop;
*/  }

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

U8 execute_cmd(U8 *cmd) {
  U64 at = link_count(cmd),
       i = 0,
       h = 0;

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

  "HashCodeFor[%d]\n",HashCodeFor("-");

//  "HashCodeFor [%d]\n", h;

// MemBIOSRep;
// Trace(ON); or Trace(OFF);

  if (h == 98262) { //cat
    if (err_check(2,2,,0,TRUE)) {
      Type(chain_pop());
    }
  }
  else if (h == 3560141) { //time
    if (err_check) {
      "%T\n", Now;
    }
  }
  else if (h == 3169 || h == 98339) { //cd & cdd
    if (err_check(,2,,0,TRUE)) {
      if (at == 2) {
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
    if (err_check(3,4,,1,TRUE)) {
      if (at == 3) {
        Copy(chain_pop, chain_pop);
      }
      else {
        h = HashCodeFor(chain_pop);

        if (h == 1495) { // "-d"
          CopyTree(chain_pop, chain_pop);
        }
      }
    }
  }
  else if (h == 98728) { //cpu
    if (err_check) {
      if (at == 1) {
        CPURep;
      }
      else {
        h = HashCodeFor(chain_pop); //"-f"

        if (h == 1497) {
          CPURep(TRUE);
        }
      }
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
/*
tcmin=1
tcmax=1
fcmin=0
fcmax=1
existance_check=FALSE
*/

  else {
  }

  return FALSE;
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
