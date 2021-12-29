#include "~/common.HC"

#define CMD_LEN 14

U8 *CMD_LIST[CMD_LEN][2] = {
{"cat","Concatenate FILE to standard output."},
{"cd", "Change the current working directory."},
{"clear", "Clear the terminal screen."},
{"cp", "Copy files and directories."},
{"df", "Display currently mounted drives."},
{"ed", "Edit / Create text files."},
{"exit", "Cause normal process termination of TempleShell."},
{"grep", "Recursively search files and\n        print lines that contain a specified string. "},
{"help", "Displays this list of TempleShell commands."},
{"ls", "List directory contents."},
{"man", "Display the source code for a specified\n        internal TempleOS command. Like Dir; - DrvRep; - etc ..."},
{"mkdir", "Make directories."},
{"mv", "Move (rename) files."},
{"rm", "Remove files or directories."}
};

U8 exec_command(SV *sv) {
  U64 q;
  U64 x = sv->count; // Count gets updated in SVPullWord();

  Bool ae = FALSE;

  U8 tokens[sv->count][128 + 1];

  for(q=0; q < x; q++) {
    SVTrim(sv,,TRUE);
    SVPullWord(sv, tokens[q]);
  }

  /*for(q=0; q < x; q++) {
    "token : %s\n", tokens[q];
  }*/

  if (!StrCmp(tokens[0], "ls")) {
    if (ae = x > 0 && x < 3) {

      "\n";
      if (x == 2) {
        Dir(tokens[1]);
      } else {
        Dir;
      }
    }
  }
  else if (!StrCmp(tokens[0], "cd")) {
    if (ae = x > 0 && x < 3) {
      if (x == 2) {
        Cd(tokens[1]);
      }
      else {
        Cd;
      }
    }
  }
  else if (!StrCmp(tokens[0], "ed")) {
    if (ae = x == 2) {
      Ed(tokens[1]);
    }
  }
  else if (!StrCmp(tokens[0], "exit")) {
    if (ae = x == 1) {
      return 1;
    }
  }
  else if (!StrCmp(tokens[0], "clear")) {
    if (ae = x == 1) {
      DocClear;
    }
  }
  else if (!StrCmp(tokens[0], "cp")) {
    if (ae = (x > 2 && x < 5)) {
      if (x == 3) {
        Copy(tokens[1], tokens[2]);
      }
      else {
        if (!StrCmp(tokens[1], "-d")) {
          CopyTree(tokens[2], tokens[3]);
        }
      }
    }
  }
  else if (!StrCmp(tokens[0], "mv")) {
    if (ae = x == 3) {
      Move(tokens[1], tokens[2]);
    }
  }
  else if (!StrCmp(tokens[0], "mkdir")) {
    if (ae = x == 2) {
      DirMk(tokens[1]);
    }
  }
  else if (!StrCmp(tokens[0], "rm")) {
    if (ae = (x > 1 && x < 4)) {
      if (x == 2) {
        Del(tokens[1]);
      }
      else {
        if (!StrCmp(tokens[1], "-d")) {
          DelTree(tokens[2]);
        }
      }
    }
  }
  else if (!StrCmp(tokens[0], "cat")) {
    if (ae = x == 2) {
      if (x == 2) {
        Type(tokens[1]);
      }
    }
  }
  else if (!StrCmp(tokens[0], "grep")) {
    if (ae = x == 2) {
      if (x == 2) {
        F(tokens[1]);
      }
    }
  }
  else if (!StrCmp(tokens[0], "man")) {
    if (ae = x == 2) {
      if (x == 2) {
        Man(tokens[1]);
      }
    }
  }
  else if (!StrCmp(tokens[0], "df")) {
    if (ae = x == 1) {
      DrvRep;
    }
  }
  else if (!StrCmp(tokens[0], "help")) {
    if (ae = x == 1) {
      U64 i;

      "\n%-6s- Description\n", "Cmd";
      "---------------------------\n";
      for (i=0; i < CMD_LEN; i++) {
        "$FG$$FG,4$%-6s$FG$- %s\n", CMD_LIST[i][0], CMD_LIST[i][1];
      }
    }
  }
  else {
    "\n";
    ExePutS(tokens[0]);
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

  "\nTempleDOS [Version 1.0]\n";
  "(c) 2021 No rights reserved. Public Domain use.\n";
  "Type 'help' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  I64 result = 0;

  while (1)
  {
    "\n%s: ", Fs->cur_dir; // Display the prompt

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