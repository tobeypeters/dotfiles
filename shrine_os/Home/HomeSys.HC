//Place this file in /Home and change
//anything you want.

#include "~/theme.HC" // This also loads tp_Compositor.HC
#include "~/patchos/patchos"

Bool started=FALSE;

U0 spawned() {
  DocTermNew;
  LBts(&Fs->display_flags,DISPLAYf_SHOW);
  WinToTop;
  WinZBufUpdate;
  DocMax; //"Unlimited" line buffer.
}

U0 UserStartUp()
{
  spawned; //Ran when a user is spawned.

  if (started) {
  }
}

U0 SrvStartUp()
{
  spawned; //Run when a srv task is spawned.
}


U0 StartUpTasks()
{
  //Terry said GOD's favorite color is BLUE
  Fs->border_src=BDS_CONST;
  Fs->border_attr=BLACK<<4+WHITE;

//  "\nBoot Time:%7.3fs\n",tS;
//  "\nTempleOS v%2.2f\n\nKernel compiled: %D %T\n",sys_os_version,sys_compile_time,sys_compile_time;
  "\nTempleOS v%2.2f\n\nBoot Time:%7.3fs  Kernel compiled: %D %T\n",tS,sys_os_version,sys_compile_time,sys_compile_time;
  
  DocCursor;

  Silent; //Turn off output, to the screen.

  CTask *user1;

  user1=User;

  XTalk(user1,"#include \"AdLib/OPL2\";\n");
  XTalk(user1,"#include \"C:/Apps/templeDOS/run\";Cd;\n");

  ACInit("/*;!*/Bible.TXT*");
  AutoComplete; //Hide autocomplete window.

  Silent(OFF); //Turn on output, to the screen.
}

StartUpTasks;

started = TRUE;
