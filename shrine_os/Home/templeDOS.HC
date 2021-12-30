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

  // Get the hash codes, for all the commands and
  // partially build a switch statement.
  "switch () {\n";
  for (q=0; q < CMD_LEN; q++) {
    "  case %d: //%s\n", HashCodeFor(CMD_LIST[q][0]), CMD_LIST[q][0];
    "    break;\n";
  }
  "  default:\n}\n";

  // Using pre-calculated hash codes, for comparison.
  // Faster and better, than using 100 StrCmp() calls.
  h = HashCodeFor(tokens[0]);

//  case 98262: //cat
//    break;
//  case 3169: //cd
//    break;
//  case 98339: //cdd
//    break;

//      if (ae = x == 2) {
//        if (x == 2) {
//          Type(tokens[1]);
//        }
//      }

//  switch (h) {
//    case "98262": //cat
//      "cat\n";
//      break;
//    case "1": //cd
//      "cd\n";
//      break;
//    default:
//  }

/*      if (ae = x > 0 && x < 3) {
        if (x == 2) {
          Cd(tokens[1]);
        }
        else {
          Cd;
        }

       if (h = 98339) {
         external("Dir;");
       }
      }

      break;
    case 3169: //cd
      "cd\n";
      break;
    case 98339: //cdd
      "cdd\n";
      break;

    case 94746189: //clear
      break;
    case 3181: //cp
      break;
    case 3076014: //date
      break;
    case 3202: //df
      break;
    case 3231: //ed
      break;
    case 3127582: //exit
      break;
    case 3181270: //grep
      break;
    case 3198785: //help
      break;
    case 3463: //ls
      break;
    case 107866: //man
      break;
    case 107989: //mem
      break;
    case 103950895: //mkdir
      break;
    case 3497: //mv
      break;
    case 109270: //now
      break;
    case 3643: //rm
      break;
    case 3560141: //time
      break;
    case 110550847: //touch
      break;
    default:
*/

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
  else if (!StrCmp(tokens[0], "cd") ||
           !StrCmp(tokens[0], "cdd")) {
    if (ae = x > 0 && x < 3) {
      if (x == 2) {
        Cd(tokens[1]);
      }
      else {
        Cd;
      }

     if (!StrCmp(tokens[0], "cdd")) {
       external("Dir;");
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
  else if (!StrCmp(tokens[0], "cat")) {
//    if (ae = x == 2) {
//      if (x == 2) {
//        Type(tokens[1]);
//      }
//    }
  }
  else if (!StrCmp(tokens[0], "touch")) {
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
  else if (!StrCmp(tokens[0], "date")) {
    if (ae = x == 1) {
      "%D\n", Now;
    }
  }
  else if (!StrCmp(tokens[0], "time")) {
    if (ae = x == 1) {
      "%T\n", Now;
    }
  }
  else if (!StrCmp(tokens[0], "now")) {
    if (ae = x == 1) {
      CDateStruct ds;
      Date2Struct(&ds,Now+local_time_offset);

      "%03tZ %03tZ %03d %T\n\n",
      ds.day_of_week, "ST_DAYS_OF_WEEK",
      ds.mon-1, "ST_MONTHS",
      ds.day_of_week,
      Now;
    }
  }
  else if (!StrCmp(tokens[0], "mem")) {
    if (ae = x == 1) {
      MemRep;
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