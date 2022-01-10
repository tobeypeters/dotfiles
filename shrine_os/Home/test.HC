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

// Before we begin ... Yes, I handle errors stupidly.
#define ERR_NONE  0 // None or too many args FALSE.
#define ERR_ARGT  1 // Too many args TRUE.
#define ERR_ARGI  2 // Invalid arg provied.
#define ERR_FILE  3 // File doesn't exist.
#define ERR_DIR   4 // Directory doesn't exist.
#define ERR_FLAGC 5 // Too many flags provided.
#define ERR_FLAGI 6 // Invalid flag provided.

U8 *ERR_MSG[4] = {
"Not a directory",
"Not a file",
"Invalid argument count",
"Invalid flag provided"
};

U0 err_msg(I64 idx = 0, U8 *fd) {
 // Could do this error stuff better i'n python.
 // Using this to allow for consistant errors and
 // formatting.
 // I don't want to use PrintErr() or PrintWarn().
 "'%s': %s\n", fd, ERR_MSG[idx];
}

#define CMD_LEN 22

U8 *CMD_LIST[CMD_LEN][2] = {
{"cat","Concatenate FILE to standard output."},
{"cd", "Change the current working directory."},
{"cdd", "Change the current working directory\n\tand display the directories contents."},
{"clear", "Clear the terminal screen."},
{"\ncp", "Copy files and directories.\n\t$FG$$FG,2$Flags:$FG$ -d Directory copy.\n"},
{"cpu", "Display a cpu representation.\n\t$FG$$FG,2$Flags:$FG$ -f Detailed cpu info."},
{"\ndate", "Display the current date."},
{"df", "Display currently mounted drives."},
{"ed", "Edit / Create text files."},
{"exit", "Cause normal process termination of TempleShell."},
{"fm", "FileManager which displays treeview of\n\tthe current or specified directory."},
{"grep", "Recursively search files and print any lines\n\twhich contain the specified string."},
{"help", "Displays this list of TempleShell commands."},
{"ls", "List directory contents."},
{"man", "Display the source code for a specified\n\tinternal TempleOS command. Like $FG$$FG,2$Dir;$FG$ - $FG$$FG,2$DrvRep;$FG$, etc."},
{"mem", "Display a memory representation."},
{"mkdir", "Make directories."},
{"mv", "Move (rename) files."},
{"now", "Display the current date and time."},
{"\nrm", "Remove files or directories.\n\t$FG$$FG,2$Flags:$FG$ -d Directory remove.\n"},
{"time", "Display the current time."},
{"touch", "Create an empty file. TempleOS also has a\n\t<$FG$$FG,2$touch$FG$> command which can update\n\tthe date & file attributes."}
};

class CC {
  U64 token_count;
  U64 flag_count;
  U64 size;
};

U0 token_trim(U8 *str, Bool left = TRUE, Bool both = FALSE) {
  // Trims leading or trailing spaces from a string.
  // left = TRUE : left trim
  // left = FALSE : right trim
  // both = TRUE : left &right trim
  if (StrLen(str) == 0) return;

  if (left || both) {
    StrUtil(str, SUF_REM_LEADING);
  }

  if (!left || both) {
    StrUtil(str, SUF_REM_TRAILING);
  }
}

I64 token_count(U8 *str, Bool count_words = TRUE, U8 delim = ' ')
{//Count the occurences of either the words or a specific char.
  I64 l = StrLen(str);

  if (l == 0) return 0;

  I64 count = 0, i = 0;

  while (i < l) {
    if (str[i] == delim) count++;
    i++;
  }
  return count + count_words;
}

I64 token_pull(U8 *cmd, U8 *out, U8 delim = ' ') {
  I64 i;

  "cmd : %s\n", cmd;
  "cmd before %d\n", cmd;
  for (i=0;*cmd != '\0' && *cmd != delim; cmd++) {
    out[i] = cmd[0];
    "%c", cmd[0];
    i++;
  };
  "\n";
  "cmd after  %d\n\n", cmd;

  return cmd;
}

U64 HashCodeFor(U8 *str) {
  // Pretty basic. But, "effective"
  // hash code generator for strings.
  U64 hash = 0;
  U64 g = 31;
  U64 i;

  for (i=0; i < StrLen(str); i++) {
    hash = g * hash + str[i];
  }

  return hash;
}

Bool FileExists(U8 *file) {
  return FileFind(file,,FUF_JUST_FILES);
}

U0 external(U8 *cmd) {
  "\n"; ExePutS(cmd);
}

U8 execute_cmd(U8 *cmd, CC *cc) {
  U64 at = token_count(cmd),
       i = 0,
       h = 0,
      fc = 0,
      tc = 0,
      ti = 0,
      fi = 0,
      ln = 0;

  Bool vd = FALSE;

  cc->flag_count = token_count(cmd,FALSE,'-');
  cc->token_count = at - cc->flag_count;
  cc->size = StrLen(cmd) / at;

  tc = cc->token_count;
  fc = cc->flag_count;

  if (tc == 0) {//Potentially, got flags and no command.
    return 0;
  }

  "cc->token_count :%d\n", cc->token_count;
  "cc->flag_count :%d\n", cc->flag_count;
  "cc->size :%d\n", cc->size;
  U8 tokens[cc->token_count][cc->size];
  U8 flags[cc->flag_count][cc->size];

  "All tokens :%d\n\n", at;
  for (i=0; i < at; i++) {
    token_trim(cmd,,TRUE);   
    if (cmd[0] == '-') {
      "fi : %d\n", fi;
      cmd = token_pull(cmd, &flags[fi]); fi++;
    }
    else {
      "ti : %d\n", ti;
      cmd = token_pull(cmd, &tokens[ti]); ti++;
    }
  }

  // List all the tokens.
  for (i=0; i < tc; i++) {
    "tokens[%d] : %s\n", i, tokens[i];
  }
  "\n";
  // List all the flags.
  for (i=0; i < fc; i++) {
    "flags[%d] : %s\n", i, flags[i];
  }

  // Get the hash codes, for all the command strings.
  /*for (q=0; q < CMD_LEN; q++) {
    "%-6s: %d\n", CMD_LIST[q][0], HashCodeFor(CMD_LIST[q][0]);
  }*/

  // Get the hash codes, for all the command strings and
  // partially build a if nest.
  /*"  if (h == %d) { //%s\n  }\n", HashCodeFor(CMD_LIST[0][0]), CMD_LIST[0][0];
  for (q=1; q < CMD_LEN; q++) {
    "  else if (h == %d) { //%s\n", HashCodeFor(CMD_LIST[q][0]), CMD_LIST[q][0];
    "  }\n";
  }
  "  else {\n  }\n";*/

  // Get the hash codes, for all the command strings and
  // partially build a switch statement.
  /*"switch () {\n";
  for (q=0; q < CMD_LEN; q++) {
    "  case %d: //%s\n", HashCodeFor(CMD_LIST[q][0]), CMD_LIST[q][0];
    "    break;\n";
  }
  "  default:\n}\n";*/

  // Using pre-calculated hash codes, for comparison.
  // Faster and better, than using 100 StrCmp() calls.

// Switch seem broke.
//  switch (h) {
//    case 0:
//      "one\n";
//      break;
//    case 99998:
//      "two\n";
//      break;
//    default:
//  }


  return 0;
}

U0 TempleDOS() {
  DocClear;

  "\n$FG,3$TempleDOS [Version 1.0]$FG$\n";
  "(c) 2022 No rights reserved. For Public Domain use.\n";
  "Type '$FG$$FG,2$help$FG$' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  U64 result = 0;

  U8 *input;

  while (1)
  {
    "\n%s: ", Fs->cur_dir; // Display prompt

    input = token_trim(GetStr(,,GSF_SHIFT_ESC_EXIT)); // Get user input

    CC cc;    


    if (StrLen(input) > 0) {
      execute_cmd(input, &cc);
    }

    input = '\0';

//    Free(tokenc);
  }
}

TempleDOS;

/*
  h = HashCodeFor(tokens[0]);

  if (h == 98262) { //cat
    if (tc == 2) {
      Type(tokens[1]);
    }
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
    if (tc == 3) {


//      if (tc == 3) {
//        Copy(tokens[1], tokens[2]);
//      }
//      else {
//        h = HashCodeFor(tokens[1]);
//
//        if (h == 1495) { // "-d"
//          CopyTree(tokens[2], tokens[3]);
//        }
//      }



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
  else if (h == 3127582) { //exit
    if (tc == 1) {
      return 1;
    }
  }
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
  else if (h == 3560141) { //time
    if (tc == 1) {
      "%T\n", Now;
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