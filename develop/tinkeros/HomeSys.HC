//Place this file in /Home and change
//anything you want.

#include "~/patchos/patcha"
#include "~/td/templeDOS"

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

  if (started)
  {
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

  
  DocCursor;

  Silent; //Turn off output, to the screen.

  CTask *user1=User;

  ACInit("::/Adam/*;!/*Bible.TXT*");
  ACInit("::/Home/patchos/*");


  AutoComplete; //Hide autocomplete window.

  XTalk(user1,"templeDOS;\n");

  Silent(OFF); //Turn on output, to the screen.
}

StartUpTasks;

started = TRUE;
