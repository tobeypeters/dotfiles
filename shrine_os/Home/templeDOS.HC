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

#define CMD_LEN 20

U8 *CMD_LIST[CMD_LEN][2] = {
{"cat","Concatenate FILE to standard output."},
{"cd", "Change the current working directory."},
{"cdd", "Change the current working directory\n\tand display the directories contents."},
{"clear", "Clear the terminal screen."},
{"cp", "Copy files and directories."},
{"date", "Display the current date."},
{"df", "Display currently mounted drives."},
{"ed", "Edit / Create text files."},
{"exit", "Cause normal process termination of TempleShell."},
{"grep", "Recursively search files and\n\tprint lines that contain a specified string."},
{"help", "Displays this list of TempleShell commands."},
{"ls", "List directory contents."},
{"man", "Display the source code for a specified\n\tinternal TempleOS command. Like $FG$$FG,2$Dir;$FG$ - $FG$$FG,2$DrvRep;$FG$ - etc ..."},
{"mem", "Display a memory representation."},
{"mkdir", "Make directories."},
{"mv", "Move (rename) files."},
{"now", "Display the current date and time."},
{"rm", "Remove files or directories."},
{"time", "Display the current time."},
{"touch", "Create an empty file. TempleOS also has\n\ta <$FG$$FG,2$touch$FG$> command which can update the date & file attributes."}
};

U0 external(U8 *cmd) {
  "\n"; ExePutS(cmd);
}

U8 exec_command(SV *sv) {
  U64 q;
  U64 x = sv->count; // Count gets updated in SVPullWord();
  U64 h = 0;

  Bool ae = FALSE;

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
    if (ae = x == 2) {
      if (x == 2) {
        Type(tokens[1]);
      }
    }
  }
  else if (h == 3169 || h == 98339) { //cd & cdd
    if (ae = x > 0 && x < 3) {
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
    if (ae = x == 1) {
      DocClear;
    }
  }
  else if (h == 3181) { //cp
    if (ae = (x > 2 && x < 5)) {
      if (x == 3) {
        Copy(tokens[1], tokens[2]);
      }
      else {
        h = HashCodeFor(tokens[1]);

        if (h == 1495) { // "-d"
          CopyTree(tokens[2], tokens[3]);
        }
      }
    }
  }
  else if (h == 3076014) { //date
    if (ae = x == 1) {
      "%D\n", Now;
    }
  }
  else if (h == 3202) { //df
    if (ae = x == 1) {
      DrvRep;
    }
  }
  else if (h == 3231) { //ed
    if (ae = x == 2) {
      Ed(tokens[1]);
    }
  }
  else if (h == 3127582) { //exit
    if (ae = x == 1) {
      return 1;
    }
  }
  else if (h == 3181270) { //grep
    if (ae = x == 2) {
      if (x == 2) {
        F(tokens[1]);
      }
    }
  }
  else if (h == 3198785) { //help
    if (ae = x == 1) {
      U64 i;

      "\n%-6s- Description\n", "Cmd";
      "---------------------------\n";
      for (i=0; i < CMD_LEN; i++) {
        "$FG$$FG,4$%-6s$FG$- %s\n", CMD_LIST[i][0], CMD_LIST[i][1];
      }
    }
  }
  else if (h == 3463) { //ls
    if (ae = x > 0 && x < 3) {

      "\n";
      if (x == 2) {
        Dir(tokens[1]);
      } else {
        Dir;
      }
    }
  }
  else if (h == 107866) { //man
    if (ae = x == 2) {
      if (x == 2) {
        Man(tokens[1]);
      }
    }
  }
  else if (h == 107989) { //mem
    if (ae = x == 1) {
      MemRep;
    }
  }
  else if (h == 103950895) { //mkdir
    if (ae = x == 2) {
      DirMk(tokens[1]);
    }
  }
  else if (h == 3497) { //mv
    if (ae = x == 3) {
      Move(tokens[1], tokens[2]);
    }
  }
  else if (h == 109270) { //now
    if (ae = x == 1) {
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
    if (ae = (x > 1 && x < 4)) {
      if (x == 2) {
        Del(tokens[1]);
      }
      else {
        h = HashCodeFor(tokens[1]);

        if (h == 1495) { // "-d"
          DelTree(tokens[2]);
        }
      }
    }
  }
  else if (h == 3560141) { //time
    if (ae = x == 1) {
      "%T\n", Now;
    }
  }
  else if (h == 110550847) { //touch
    if (ae = x == 2) {
      // Currently only creates an empty file.
      // The templeOS touch command can update
      // file attributes and the date.

      // FileFind is the closes thing I've found,
      // to a fileexists(). I'm still looking.
      if (!FileFind(tokens[1])) {
        FileWrite(tokens[1], NULL, 0);
      }
    }
  }
  else {
    external(tokens[0]);
    ae = TRUE;
  }

  if (x > 0 && !ae) {
    "Error: %s - Argument count\n", tokens[0];
  }

  return 0;
}

U0 TempleDOS()
{
  DocClear;

  "\n$FG,3$TempleDOS [Version 1.0]$FG$\n";
  "(c) 2021 No rights reserved. For Public Domain use.\n";
  "Type 'help' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  I64 result = 0;


  while (1)
  {
    "\n%s: ", Fs->cur_dir; // Display the prompt

    SV sv;
    sv.begin = GetStr(,,GSF_SHIFT_ESC_EXIT); // Grab user input
    sv.size = StrLen(sv.begin);
    sv.count = SVWordCount(&sv);
    sv.fp = sv.begin;

    if (sv.count > 0) {
      result = exec_command(&sv);
    }

    Free(sv.fp);

    if (result) {
      break;
    }
  }
}

//TempleDOS;