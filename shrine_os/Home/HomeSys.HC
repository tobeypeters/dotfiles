//Place this file in /Home and change
//anything you want.

#include "~/templeDOS.HC"
#include "~/Theme.HC"

Bool started = FALSE;

U0 spawned() {
  DocTermNew;
  LBts(&Fs->display_flags,DISPLAYf_SHOW);
  WinToTop;
  WinZBufUpdate;
}

U0 UserStartUp()
{
   spawned; //Ran when a user is spawned.

   if (started) {
     TempleDOS;
   }
}

U0 SrvStartUp()
{
  spawned; //Run when a srv task is spawned.
}


U0 StartUpTasks()
{
  "Boot Time:%7.3fs\n",tS;

  Silent; //No output to scrn

  CTask *user1;

  user1=User;

  XTalk(user1,"Cd;\n");
  XTalk(user1,"TempleDOS;\n");

  ACInit("/*;!*/Bible.TXT*");

  Silent(OFF); //No output to scrn
}

StartUpTasks;

"\nTempleOS V%5.3f\t%D %T\n\n",sys_os_version,sys_compile_time,sys_compile_time;

started = TRUE;
