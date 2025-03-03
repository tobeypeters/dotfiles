//Place this file in /Home and change
//anything you want.

#include "~/theme.HC" // This also loads tp_Compositor.HC
#include "~/patchos/patchos"
#include "/Apps/templeDOS/templeDOS"

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
    templeDOS;
  }
}

U0 SrvStartUp()
{
  spawned; //Run when a srv task is spawned.
}


U0 StartUpTasks()
{
  "\nTempleOS V%5.3f\t%D %T\n",sys_os_version,sys_compile_time,sys_compile_time;

  //Terry said GOD's favorite color is BLUE
  Fs->border_src=BDS_CONST;
  Fs->border_attr=BLACK<<4+WHITE;
  
  DocCursor;

  Silent; //Turn off output, to the screen.

  CTask *user1;

  user1=User;

//  XTalk(user1,"#include \"AdLib/OPL2\";\n");
//  XTalk(user1,"#include \"C:/Apps/templeDOS/run\";Cd;\n");

  XTalk(user1,"templeDOS;\n");

  ACInit("/*;!*/Bible.TXT*");
  AutoComplete; //Hide autocomplete window.

  Silent(OFF); //Turn on output, to the screen.
}

StartUpTasks;

started = TRUE;
