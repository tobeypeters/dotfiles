//Place this file in /Home and change
//anything you want.

#include "~/patchos/patcha"
#include "~/td/templeDOS"

Bool started=FALSE;

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

  Fs->text_attr=BLACK<<4+WHITE;
}

U0 UserStartUp()
{
  spawned; //Ran when a user is spawned.

  if (started)
  {
    if (!DocEntryRan) templeDOS;
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


//  AutoComplete; //Hide autocomplete window.

  XTalk(user1,"templeDOS;\n");

  Silent(OFF); //Turn on output, to the screen.
}

Fs->text_attr=BLACK<<4+WHITE;

StartUpTasks;

started = TRUE;
