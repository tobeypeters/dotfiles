#include "~/theme" // This also loads tp_Compositor.HC
#include "~/patchos/patcha"

WALL_DEBUG=WALL_FPS=WALL_MEM=WALL_CPU=FALSE;

//WALL_DEBUG=TRUE;

#include "~/demos/eye_wallpaper"
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

  if (started)
  {
    if (!DocEntryRan) templeDOS;
  }
}

U0 SrvStartUp()
{
  spawned; //Run when a srv task is spawned.
}


U0 StartUpTasks()
{
  "\nTempleOS V%5.3f\t%D %T\n",sys_os_version,sys_compile_time,sys_compile_time;

  //Terry said GOD's favorite color is BLUE
  Fs->border_src=BDS_CONST;
  Fs->border_attr=BLACK<<4+WHITE;
  
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
