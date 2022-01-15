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

//YES, I handling validation and errors horribly.
class EC {
  U8 *tokens;
  U8 *flags;
  I64 tc;
  I64 fc;
};

U0 err_disp(U8 *err, U8 *tok="Usage") {
  "`[%s]`: %s ...\n", tok, err;
}

//Bool err_check(U8 *tokens, U8 *flags,
//               U64 tc, U64 fc,
Bool err_check(EC *ec,
               U64 tcmin=1, U64 tcmax=1,
               U64 fcmin=0, U64 fcmax=0, 
               Bool dir_check=FALSE, Bool file_check=FALSE)
{//Used to do all the "basic" usage errors.

//  "ec->tokens[0] : %s\n", ec->tokens[1];
/*
  if (

(tcmin > tc || tc > tcmax)
||
(fc > 0 && (fcmin <= fc <= fcmax))

     )

  {
    err_disp("Invalid number of parameters and/or flags provided");
    return FALSE;
  }

  if (dir_check || file_check) {
    U64 i;

    if (dir_check) {
      for (i=1;i < tc; i++) {
        if (!IsDir(tokens[i])) {
          err_disp("Not a directory", tokens[i]);
          return FALSE;
        }
      }
    }

    if (file_check) {
      for (i=0;i < tc; i++) {
        if (!FileExists(tokens[i])) {
          err_disp("Not a file", tokens[i]);
          return FALSE;
        }
      }
    }
  }
*/ 
  return TRUE;
}

#define CMD_LEN 22

U8 *CMD_LIST[CMD_LEN][2] = {
{"cat",   "Concatenate FILE to standard output."},
{"cd",    "Change the current working directory."},
{"cdd",   "Change the current working directory\n\tand display the directories contents."},
{"clear", "Clear the terminal screen."},
{"\ncp",  "Copy files and directories.\n\t$FG$$FG,2$Flags:$FG$ -d Directory copy.\n"},
{"cpu",   "Display a cpu representation.\n\t$FG$$FG,2$Flags:$FG$ -f Detailed cpu info."},
{"\ndate","Display the current date."},
{"df",    "Display currently mounted drives."},
{"ed",    "Edit / Create text files."},
{"exit",  "Cause normal process termination of TempleShell."},
{"fm",    "FileManager which displays treeview of\n\tthe current or specified directory."},
{"grep",  "Recursively search files and print any lines\n\twhich contain the specified string."},
{"help",  "Displays this list of TempleShell commands."},
{"ls",    "List directory contents."},
{"man",   "Display the source code for a specified\n\tinternal TempleOS command. Like $FG$$FG,2$Dir;$FG$ - $FG$$FG,2$DrvRep;$FG$, etc."},
{"mem",   "Display a memory representation."},
{"mkdir", "Make directories."},
{"mv",    "Move (rename) files."},
{"now",   "Display the current date and time."},
{"\nrm",  "Remove files or directories.\n\t$FG$$FG,2$Flags:$FG$ -d Directory remove.\n"},
{"time",  "Display the current time."},
{"touch", "Create an empty file. TempleOS also has a\n\t<$FG$$FG,2$touch$FG$> command which can update\n\tthe date & file attributes."}
};

U0 token_trim(U8 *str, Bool left = TRUE, Bool both = FALSE)
{//Trims leading or trailing spaces from a string.
 //left = TRUE : left trim
 //left = FALSE : right trim
 //both = TRUE : left &right trim
  if (StrLen(str) == 0) return;

  if (left || both) {
    StrUtil(str, SUF_REM_LEADING);
  }

  if (!left || both) {
    StrUtil(str, SUF_REM_TRAILING);
  }
}

U64 token_count(U8 *str, Bool count_words = TRUE, U8 delim = ' ')
{//Count the occurences of either the words or a specific char.
  U64 l = StrLen(str);

  if (l == 0) return 0;

  U64 i = 0,
  count = 0;

  while (i < l) {
    if (str[i] == delim) {
      count++;
    }

    i++;
  }

  return count + count_words;
}

U64 token_pull(U8 *str, U8 *out, U8 delim = ' ')
{//Pull off the first token off a str and assign
 //it to what you pasted in as out.
  I64 i;

  for (i=0;*str != '\0' && *str != delim; str++) {
    out[i] = str[0];
    i++;
  };
  if (i > 0) out[i] = '\0';
  
  while (*str == delim) str++;

  return str;
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

Bool FileExists(U8 *file) 
{//Formatted File existence checker.
  return FileFind(file,,FUF_JUST_FILES);
}

U0 external(U8 *cmd) {
  "\n"; ExePutS(cmd);
}

#define MAX_TOKENS  3
#define MAX_FLAGS   3
#define MAX_TKLEN 161

U0 tester(U8 *test) {
  "test[0] : %s\n", test;
}

U8 execute_cmd(U8 *cmd) {
  U64 at = token_count(cmd),
       i = 0,
       h = 0,
      fc = 0,
      tc = 0,
      ti = 0,
      fi = 0,
      ln = 0;

  EC ec;

  fc = token_count(cmd,FALSE,'-');
  tc = at - fc;

  //This tokens / flag system is alright. But, not great.
  //You can't give flags values.  For example: -fg_color "#FF00FF".
  // 
  //       [num_of]    [len] - 160 WAY too big.
  U8 tokens[MAX_TOKENS][MAX_TKLEN];
  U8   flags[MAX_FLAGS][MAX_TKLEN];

  //Time to split our tokens up.
  for (i=0; i < at; i++) {
    token_trim(cmd,FALSE,TRUE);
    if (cmd[0] == '-') {
      cmd = token_pull(cmd, flags[fi]); fi++;
    }
    else {
      cmd = token_pull(cmd, tokens[ti]); ti++;
    }
  }

  ec.tokens = tokens;
  ec.flags = flags;
  ec.tc = tc;
  ec.fc = fc;

  tester(tokens);

  //List all the tokens.
  /*for (i=0; i < tc; i++) {
    "tokens[%d] : %s\n", i, tokens[i];
  }
  "\n";
  //List all the flags.
  for (i=0; i < fc; i++) {
    "flags[%d] : %s\n", i, flags[i]$WW,1$;
  }*/

  /*U64 q;
  //Get the hash codes, for all the command strings.
  for (q=0; q < CMD_LEN; q++) {
    "%-6s: %d\n", CMD_LIST[q][0], HashCodeFor(CMD_LIST[q][0]);
  }*/

  //Get the hash codes, for all the command strings and
  //partially build a if nest.
  /*"  if (h == %d) { //%s\n  }\n", HashCodeFor(CMD_LIST[0][0]), CMD_LIST[0][0];
  for (q=1; q < CMD_LEN; q++) {
    "  else if (h == %d) { //%s\n", HashCodeFor(CMD_LIST[q][0]), CMD_LIST[q][0];
    "  }\n";
  }
  "  else {\n  }\n";*/

  //Get the hash codes, for all the command strings and
  //partially build a switch statement.
  /*"switch () {\n";
  for (q=0; q < CMD_LEN; q++) {
    "  case %d: //%s\n", HashCodeFor(CMD_LIST[q][0]), CMD_LIST[q][0];
    "    break;\n";
  }
  "  default:\n}\n";*/

  ///Switch seems broke.
  /*switch (h) {
      case 0:
        "one\n";
        break;
      case 99998:
        "two\n";
        break;
      default:
    }*/

  //Using pre-calculated hash codes, for comparison.
  //IMO : Faster and better, than using 100 StrCmp() calls.
  

//EC *ec
//tcmin=1
//tcmax=1
//fcmin=0
//fcmax=0
//dir_check=FALSE
//file_check=FALSE)

//err_check(tokens, flags);

  h = HashCodeFor(tokens[0]);

  if (h == 3127582) { //exit
    if (err_check(&ec)) {
//    if (err_check(tokens,flags,tc,fc)) {
      return 1;
    }
  }
  else if (h == 3560141) { //time
//    if (err_check(&ec)) {
//      "%T\n", Now;
//    }
  }
  else if (h == 98262) { //cat
//    if (err_check(&ec,2,2,,,,TRUE)) {
//      Type(tokens[1]);
//    }
  }
  else if (h == 3169 || h == 98339) { //cd & cdd
    if (0 < tc < 3) {
      if (tc == 2) {
        Cd(tokens[1]);
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
    if (tc == 1) {
      DocClear;
    }
  }
  else if (h == 3181) { //cp
    if (2 < tc < 5) {


      if (tc == 3) {
        Copy(tokens[1], tokens[2]);
      }
      else {
        
//        h = HashCodeFor(tokens[1]);
//
//        if (h == 1495) { // "-d"
//          CopyTree(tokens[2], tokens[3]);
//        }
      }


    }
  }
  else if (h == 98728) { //cpu
    if (0 < tc < 3) {
      if (tc == 1) {
        CPURep;
      }
//      else {
//        h = HashCodeFor(tokens[1]); //"-f"

//        if (h == 1497) {
//          CPURep(TRUE);
//        }
//      }
    }
  }
  else if (h == 3076014) { //date
    if (tc == 1) {
      "%D\n", Now;
    }
  }
  else if (h == 3202) { //df
    if (tc == 1) {
      DrvRep;
    }
  }
  else if (h == 3231) { //ed
    if (tc == 2) {
      Ed(tokens[1]);
    }
  }
  else {
  }







  return 0;
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
    "\n%s: ", Fs->cur_dir; // Display prompt

    // Get user input
    input = token_trim(GetStr(,,GSF_SHIFT_ESC_EXIT), FALSE, TRUE);

    if (StrLen(input) > 0) {
      result = execute_cmd(input);
    }

    input = '\0';

    if (result) break;
  }
}

TempleDOS;

/*
  else if (h == 3271) { //fm
    // Could refactor this section,
    // in another language.
    if (0 < tc < 3) {
      if (tc == 1) {
        MiniFM;
        return 0;
      }
      else {
      }
    }

  }
  else if (h == 3181270) { //grep
    if (tc == 2) {
      F(tokens[1]);
    }
  }
  else if (h == 3198785) { //help
    if (tc == 1) {
      "\n%-6s\tDescription\n", "Cmd";
      "---------------------------\n";
      for (i=0; i < CMD_LEN; i++) {
        "$FG$$FG,2$%-6s $FG$\t%s\n", CMD_LIST[i][0], CMD_LIST[i][1];
      }
    }
  }
  else if (h == 3463) { //ls
    if (0 < tc < 3) {
      "\n";
      if (tc == 2) {
        Dir(tokens[1]);
      } else {
        Dir;
      }
    }
  }
  else if (h == 107866) { //man
    if (tc == 2) {
      Man(tokens[1]);
    }
  }
  else if (h == 107989) { //mem
    if (tc == 1) {
      MemRep;
    }
  }
  else if (h == 103950895) { //mkdir
    if (tc == 2) {
      DirMk(tokens[1]);
    }
  }
  else if (h == 3497) { //mv
    if (tc == 3) {
      Move(tokens[1], tokens[2]);
    }
  }
  else if (h == 109270) { //now
    if (tc == 1) {
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
    if (1 < tc < 4) {
      if (tc == 2) {
        Del(tokens[1]);
      }
//      else {
//        h = HashCodeFor(tokens[1]);

//        if (h == 1495) { //"-d"
//          DelTree(tokens[2]);
//        }
//      }
    }
  }
  else if (h == 110550847) { //touch
    if (tc == 2) {
      // Currently only creates an empty file, if
      // it doesn't exist already.
      if (!FileExists(tokens[1])) {
        // Off-hand, looks like Touch() doesn't create
        // files. I'll look more at it and touchfile().
        FileWrite(tokens[1], NULL, 0);
      }
      else {
        Touch(tokens[1],"");
      }
    }
  }
  else {
    external(tokens[0]);
  }
*/