Cd(__DIR__);;

Bool APP_QUIT=FALSE;

/*U0 AnimateTask(I64)
{
  while (!APP_QUIT)
  {

    Sleep(30);
  }
}*/

//Fs->animate_task=Spawn(&AnimateTask,NULL,"saver_animate",,);

U0 msg_test()
{
I64 arg1,arg2;
try {
  while (!APP_QUIT) {
    switch (GetMsg(&arg1,&arg2,1<<MSG_KEY_DOWN+1<<MSG_KEY_UP)) {
      case MSG_KEY_DOWN:
        switch (arg1) {
          case CH_SHIFT_ESC:
          case CH_ESC:
            APP_QUIT=TRUE;
        }
        break;
      case MSG_KEY_UP:
        AdamLog("here\n");
        break;
    }
  }
} catch
  PutExcept;
}
msg_test;