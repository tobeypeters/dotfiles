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

#include "~/common.HC"

#define CMD_LEN 22

U8 *CMD_LIST[CMD_LEN][2] = {
{"cat","Concatenate FILE to standard output."},
{"cd", "Change the current working directory."},
{"cdd", "Change the current working directory\n\tand display the directories contents."},
{"clear", "Clear the terminal screen."},
{"\ncp", "Copy files and directories.\n\t$FG$$GREEN$Flags:$FG$ -d Directory copy.\n"},
{"cpu", "Display a cpu representation.\n\t$FG$$GREEN$Flags:$FG$ -f Detailed cpu info."},
{"\ndate", "Display the current date."},
{"df", "Display currently mounted drives."},
{"ed", "Edit / Create text files."},
{"exit", "Cause normal process termination of TempleShell."},
{"fm", "FileManager which displays treeview of\n\tthe current or specified directory."},
{"grep", "Recursively search files and print any lines\n\twhich contain the specified string."},
{"help", "Displays this list of TempleShell commands."},
{"ls", "List directory contents."},
{"man", "Display the source code for a specified\n\tinternal TempleOS command. Like $FG$$GREEN$Dir;$FG$ - $FG$$GREEN$DrvRep;$FG$, etc."},
{"mem", "Display a memory representation."},
{"mkdir", "Make directories."},
{"mv", "Move (rename) files."},
{"now", "Display the current date and time."},
{"\nrm", "Remove files or directories.\n\t$FG$$GREEN$Flags:$FG$ -d Directory remove.\n"},
{"time", "Display the current time."},
{"touch", "Create an empty file. TempleOS also has a\n\t<$FG$$GREEN$touch$FG$> command which can update\n\tthe date & file attributes."}
};

// File / directory error messages.
U8 *ERR_MSG[2] = {
"Not a directory",
"Not a file"
};

//"Invalid argument count.";
//"Invalid flag(s) provided.";

U0 err_msg(I64 idx = 0, U8 *fd) {
 // Could do this error stuff better in python.
 // Using this to allow for consistant errors and
 // formatting.
 // I don't want to use PrintErr() or PrintWarn().
 "'%s': %s\n", fd, ERR_MSG[idx];
}

U0 external(U8 *cmd) {
  "\n"; ExePutS(cmd);
}

U8 exec_command(SV *sv) {
  U64 q;
  U64 x = sv->count; // Count gets updated in SVPullWord();
  U64 h = 0;

  Bool ace = FALSE;
  Bool afe = TRUE;

  U8 tokens[sv->count][128 + 1];

  for(q=0; q < x; q++) {
    SVTrim(sv,,TRUE);
    SVPullWord(sv, tokens[q]);
  }

  // List all the tokens.
  /*for (q=0; q < x; q++) {
    "token : %s\n", tokens[q];
  }*/

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

  h = HashCodeFor(tokens[0]);

  if (h == 98262) { //cat
    if (ace = x == 2) {
      Type(tokens[1]);
    }
  }
  else if (h == 3169 || h == 98339) { //cd & cdd
    if (ace = 0 < x < 3) {
      if (x == 2) {
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
    if (ace = x == 1) {
      DocClear;
    }
  }
  else if (h == 3181) { //cp
    if (ace = (2 < x < 5)) {
      if (x == 3) {
        Copy(tokens[1], tokens[2]);
      }
      else {
        h = HashCodeFor(tokens[1]);

        if (afe = h == 1495) { // "-d"
          CopyTree(tokens[2], tokens[3]);
        }
      }
    }
  }
  else if (h == 98728) { //cpu
    if (ace = (0 < x < 3)) {
      if (x == 1) {
        CPURep;
      }
      else {
        h = HashCodeFor(tokens[1]); //"-f"

        if (afe = h == 1497) {
          CPURep(TRUE);
        }
      }
    }
  }
  else if (h == 3076014) { //date
    if (ace = x == 1) {
      "%D\n", Now;
    }
  }
  else if (h == 3202) { //df
    if (ace = x == 1) {
      DrvRep;
    }
  }
  else if (h == 3231) { //ed
    if (ace = x == 2) {
      Ed(tokens[1]);
    }
  }
  else if (h == 3127582) { //exit
    if (ace = x == 1) {
      return 1;
    }
  }
  else if (h == 3271) { //fm
    if (ace = (0 < x < 3)) {
      if (x == 1) {
        MiniFM;
      }
      else {
        if (IsDir(tokens[1])) {
          MiniFM(tokens[1]);
        }
        else {
          err_msg(0, tokens[1]);
        }
      }
    }
  }
  else if (h == 3181270) { //grep
    if (ace = x == 2) {
      F(tokens[1]);
    }
  }
  else if (h == 3198785) { //help
    if (ace = x == 1) {
      U64 i;

      "\n%-6s\tDescription\n", "Cmd";
      "---------------------------\n";
      for (i=0; i < CMD_LEN; i++) {
        "$FG$$GREEN$%-6s $FG$\t%s\n", CMD_LIST[i][0], CMD_LIST[i][1];
      }
    }
  }
  else if (h == 3463) { //ls
    if (ace = 0 < x < 3) {
      "\n";
      if (x == 2) {
        Dir(tokens[1]);
      } else {
        Dir;
      }
    }
  }
  else if (h == 107866) { //man
    if (ace = x == 2) {
      Man(tokens[1]);
    }
  }
  else if (h == 107989) { //mem
    if (ace = x == 1) {
      MemRep;
    }
  }
  else if (h == 103950895) { //mkdir
    if (ace = x == 2) {
      DirMk(tokens[1]);
    }
  }
  else if (h == 3497) { //mv
    if (ace = x == 3) {
      Move(tokens[1], tokens[2]);
    }
  }
  else if (h == 109270) { //now
    if (ace = x == 1) {
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
    if (ace = (1 < x < 4)) {
      if (x == 2) {
        Del(tokens[1]);
      }
      else {
        h = HashCodeFor(tokens[1]);

        if (afe = h == 1495) { //"-d"
          DelTree(tokens[2]);
        }
      }
    }
  }
  else if (h == 3560141) { //time
    if (ace = x == 1) {
      "%T\n", Now;
    }
  }
  else if (h == 110550847) { //touch
    if (ace = x == 2) {
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
    ace = TRUE;
  }

  if (x > 0 && (!ace || !afe)) {
    U8 *err_msg = "";

    if (!ace) {
      err_msg = "Invalid argument count.";
    }

    if (!afe) {
      err_msg = "Invalid flag(s) provided.";
    }

    "$FG$$GREEN$Error:$FG$ %s\n", err_msg;
  }

  return 0;
}

U0 TempleDOS()
{
  DocClear;

  "\n$CYAN$TempleDOS [Version 1.0]$FG$\n";
  "(c) 2022 No rights reserved. For Public Domain use.\n";
  "Type '$FG$$GREEN$help$FG$' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  U64 result = 0;

  // "Hash Code : %d\n", HashCodeFor("fm");

  while (1)
  {
    "\n%s: ", Fs->cur_dir; // Display prompt

    SV sv;
    sv.begin = GetStr(,,GSF_SHIFT_ESC_EXIT); // Get user input
    sv.size = StrLen(sv.begin);
    sv.count = SVWordCount(&sv);
    sv.fp = sv.begin;

    if (sv.count > 0) {
      result = exec_command(&sv); // Execute terminal command
    }

    Free(sv.fp);

    if (result) {
      break;
    }
  }
}

//TempleDOS;
