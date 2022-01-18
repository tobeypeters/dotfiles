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
//the popping logic.  No need. CAUSE, all we need to really
//do is treat begin as a pointer or actually make a pointer
//and move it back & forth.
#define MAX_LINKS 256
#define LINK_LEN  256

U8 chain[MAX_LINKS][LINK_LEN];
U64 links = 0,
    begin = 0;

U64 tc = 0,
    fc = 0;

U8 chain_peek(U64 idx)
{//Peek at a link on the chain.
 if (idx < links) {
//   "chain_peek [%s]\n", chain[idx];
   return chain[idx];
 }

 return "";
}

//Yes, I'm handing error checking and validation horribly.
U0 err_print(U8 *msg, U8 *link="Usage")
{//Print our err_msg.
  "`[$FG,3$%s$FG$]`: %s ...\n", link, msg;
}

Bool err_check(U64 tcmin=1, U64 tcmax=1,
               U64 fcmin=0, U64 fcmax=1,
               Bool existance_check=FALSE)
{//Cheap error checker.
  if ((tc < tcmin || tc > tcmax) ||
      (fc > fcmin || fc > fcmax)) {
    err_print("Invalid number of arguments provided");
    return FALSE;
  }

  if (existance_check) {//Make sure all files & directories exist.
    U64 i = begin; //begin should be 1, from prev chain_pop

    while (i <= links) {
      "filefind : [%s] i : [%d] links [%d] begin : [%d]\n",chain_peek(i),i,links, begin;

      //if (!FileFind(chain_peek(i))) {
      //  err_print("does not exist",chain[i]);
      //  return FALSE;
      //}

      i++;
    }
  }

  return TRUE;
}

U0 chain_clean()
{//Clear the chain.
  MemSet(chain, '\0', sizeof(U8)*MAX_LINKS*LINK_LEN);

  links = begin = 0;
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

//  "link_count [%d]\n", count+count_links;

  return count + count_links;
}



U64 chain_push(U8 *si, U8 delim = ' ')
{//Weld a link, onto the chain.
  U64 i = 0;

  while (si[0] != '\0' && si[0] != delim) {
    chain[links][i] = si[0];
//    "%c", si[0];
    si++; i++;
  }
  if (i > 0) chain[links][i] = '\0';
//  "\nchain_push [%s]\n\n", chain[links];

  links++;  

  while (*si == delim) si++;

  return si;
}

U8 chain_pop()
{//Pop an link, off the chain.
 if (links > 0) {
   U8 *result = chain[begin];

   begin++;
   links--;

//   "chain_pop [%s], chain[%s]\n", result, chain[begin];
   chain[begin][0] = '\0';

   return result;
 }

 return "";
}

U64 HashCodeFor(U8 *str) 
{//Hash code generator for strings.
  U64 hash = 0;
  U64 g = 31;
  U64 i;

  for (i=0; i < StrLen(str); i++) {
    hash = g * hash + str[i];
  }

  return hash;
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

    //h = HashCodeFor(chain_peek(begin));
    h = HashCodeFor(chain_pop);
  }

//  "HashCodeFor [%d]\n", h;

/*
tcmin=1
tcmax=1
fcmin=0
fcmax=1
existance_check=FALSE
*/

  if (h == 3127582) { //exit
    if (err_check) {
      return 1;
    }
  }
  else if (h == 98262) { //cat
    if (err_check(2,2,,0,TRUE)) {
      chain_pop;
//      Type(chain_pop);
    }
  }
  else if (h == 3560141) { //time
//    if (err_check) {
//      "%T\n", Now;
//    }
  }
  else if (h == 3169 || h == 98339) { //cd & cdd
//    if (err_check(1,3,,,TRUE)) {
//      if (tc == 2) {
//        Cd(tokens[1]);
//      }
//      else {
//        Cd;
//      }

//      if (h == 98339) {
//        external("Dir;");
//      }
//    }
  }
  else if (h == 94746189) { //clear
//    if (err_check) {
//      DocClear;
//    }
  }
  else {
  }

  return FALSE;
}

U0 TempleDOS() {
  DocClear;

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


