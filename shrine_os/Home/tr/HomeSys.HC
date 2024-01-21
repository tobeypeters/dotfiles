// Place this file in /Home and change
// anything you want.

// #include "~/Themes/Gruvbox.HC"

//Run each time a user a spawned
U0 UserStartUp()
{
  DocTermNew;
  Type("::/Doc/Start.DD");
  LBts(&Fs->display_flags,DISPLAYf_SHOW);
  WinToTop;
  WinZBufUpdate;
  Dir;
}

//Run each time a srv task is spawned.
U0 SrvStartUp()
{
  DocTermNew;
  LBts(&Fs->display_flags,DISPLAYf_SHOW);
  WinToTop;
  WinZBufUpdate;
}

U0 StartUpTasks()
{
  CTask *user1;
  user1=User;
  WinMax(user1);
  "Boot Time:%7.3fs\n",tS;
  Silent;	//no output to scrn
  ACInit("/*;!*/Bible.TXT*");
  Silent(OFF); //no output to scrn
}

StartUpTasks;

"\nTempleOS V%5.3f\t%D %T\n\n",sys_os_version,sys_compile_time,sys_compile_time;
