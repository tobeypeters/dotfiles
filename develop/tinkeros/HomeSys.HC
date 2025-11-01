#include "~/patchos/patcha"
#include "~/td/templeDOS"

#include "~/eye_wallpaper"

Bool started=FALSE;

// Sysmenu display values
WALL_DEBUG=FALSE;
WALL_CPU=FALSE;
WALL_MEM=FALSE;
WALL_FPS=FALSE;

public U0 ApplyColor()
{
  Fs->border_src=BDS_CONST;
  Fs->border_attr=BLACK<<4+WHITE;
  Fs->text_attr=BLACK<<4+WHITE;
}
public U0 DrawStdMs(CDC *dc,I64 x,I64 y) 
{// Override the mouse cursor.
  dc->color=LTRED;

  dc->thick=1;
  dc->flags&=~(DCF_TRANSFORMATION|DCF_SYMMETRY);
  GrArrow3(dc,x+6,y+6,0,x,y,0);
} gr.fp_draw_ms=&DrawStdMs;

U0 spawned() {
  DocTermNew;
  LBts(&Fs->display_flags,DISPLAYf_SHOW);
  WinToTop;
  WinZBufUpdate;
  DocMax; //"Unlimited" line buffer.

  ApplyColor;
}

U0 UserStartUp()
{
  spawned; //Ran when a user is spawned.


  if (started) {
    if (!DocEntryRan) templeDOS;
  }
}

U0 SrvStartUp() {
  spawned; //Run when a srv task is spawned.
}


U0 StartUpTasks()
{
  "\nTempleOS V%5.3f\t%D %T\n",sys_os_version,sys_compile_time,sys_compile_time;
 
  DocCursor;

  Silent; //Turn off output, to the screen.

  ACInit("::/Adam/*;!/*Bible.TXT*");
  ACInit("::/Home/patchos/*");

  CTask *user1=User;
  XTalk(user1,"templeDOS;\n");

  ApplyColor;

  AutoComplete; //Hide autocomplete window.

  Silent(OFF); //Turn on output, to the screen.
}

StartUpTasks;

started = TRUE;
