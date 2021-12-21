#include "~/common.HC"

#define CMDS_LEN 10

U0 PrintHelp()
{
  "Available commands:\n";
  I64 i;
  for (i=0; i<CMDS_LEN; i++)
  {
    //"%s - %s\n", cmds[i], cmds_help[i];
  }
}

U0 not_used() {
/*
  // cd
  if (StrNCmp(input,"cd",2) == 0) {

   Cd(cur_args->argv[0]);
  }
  // ls
  else if (StrNCmp(input,"ls",2) == 0) {
    if (num_args == 1) {
      cur_args = GetArgs(input);
      Dir(cur_args->argv[0]);
      FreeArgs(cur_args);
    } else {
      Dir;
    }
  }
  // help
  else if (StrNCmp(input,"help",4) == 0) {
    PrintHelp();
  }
  // edit
  else if (StrNCmp(input,"edit",4) == 0) {
    Ed(cur_args->argv[0]);
  }
  // cp
  else if (StrNCmp(input,"cp",2) == 0) {
    Copy(cur_args->argv[0], cur_args->argv[1]);
  }
  // mv
  else if (StrNCmp(input,"mv",2) == 0) {
    Copy(cur_args->argv[0], cur_args->argv[1]);
  }
  // mkdir
  else if (StrNCmp(input,"mkdir",5) == 0) {
    DirMk(cur_args->argv[0]);
  }
  // rm
  else if (StrNCmp(input,"rm",2) == 0) {
    Del(cur_args->argv[0]);
  }
*/

}

I64 exec_command(SV *sv) {
  I64 q;
  I64 x = sv->count; // Count gets updated in SVPullWord();

  Bool ae = FALSE;

  U8 tokens[sv->count][128 + 1];

  for(q=0; q < x; q++) {
    SVTrim(sv);
    SVPullWord(sv, tokens[q]);
  }
 
  /*for(q=0; q < x; q++) {
    "token :%s\n", tokens[q];
  }*/


  if (!StrCmp(tokens[0], "exit")) {

    if (ae = x == 1) {
      return 1;
    }

  }
  else if (!StrCmp(tokens[0], "clear")) {

    if (ae = x == 1) {
      DocClear;
    }

  }
  else if (!StrCmp(tokens[0], "cd")) {

    if (ae = x > 0 && x < 3) {
      if (x == 2) {
        Cd(tokens[1]);
      }
      else {
        Cd("~");
      }
    }

  }
  else if (!StrCmp(tokens[0], "ls")) {

    if (ae = x > 0 && x < 3) {

      if (x == 2) {
        Dir(tokens[1]);
      } else {
        Dir;
      }
    }

  }
  else if (!StrCmp(tokens[0], "help")) {
    //PrintHelp();
  }
  else if (!StrCmp(tokens[0], "ed")) {

    if (ae = x == 2) {
      Ed(tokens[1]);
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
  else {
    ExePutS(tokens[0]);
    ae = TRUE;
  }
	
  if (x > 0 && !ae) {
    "Error: %s - Argument count\n", tokens[0];
  }

  return 0;
}

U0 TempleShell()
{
  "\nTempleShell [Version 1.0]\n";
  "(c) 2021 No rights reserved. Public Domain use.\n";
  "Type 'help' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  I64 result = 0;

  while (1)
  {
    "\n%s # ", Fs->cur_dir; // Display the prompt

    SV sv;
    sv.begin = GetStr(,,GSF_SHIFT_ESC_EXIT); // Grab user input
    sv.size = StrLen(sv.begin);
    sv.count = SVWordCount(&sv);
    sv.fp = sv.begin;


    if (sv.count > 0) {
      result = exec_command(&sv);
    }

    Free(sv.fp);

    if (result) {
      return;
    }
  }
}

TempleShell;
