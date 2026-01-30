/*

ABOUT 10% of a screensaver implementation.

*/
Cd(__DIR__);;

I64 begin=KbdMsEvtTime;
I64 elapsed=0;
/*
U8 reg_saver[255];
*/
U0 (*draw_saver)();

//U8 reg_key[255]="TempleOS/screensaver";
//U8 reg_val[255]="F64 best_score=9999;\n";
//U8 reg_val_up[255];
//MemCpy(reg_val_up,reg_val,
//       sizeof(reg_val));
//RegDft(reg_key,reg_val);
//RegExe(reg_key);

U64 GetElapsedEvtTime() return (GetTSC-begin)/cnts.time_stamp_freq;

U0 load_saver(U8 *saver="./default.HC")
{
  if (FileFind(saver))
  {
    ExePrint("#include \"%s\"",saver);
  }
} load_saver;

Bool APP_QUIT=FALSE;

U0 AnimateTask(I64)
{
  while (!APP_QUIT)
  {
    elapsed=GetElapsedEvtTime;

    if (elapsed>3)
      draw_saver();

    Sleep(10);
  }
}

Fs->animate_task=Spawn(&AnimateTask,NULL,"saver_animate",,);

I64 arg1,arg2;
try {
  while (!APP_QUIT) {
    switch (GetMsg(&arg1,&arg2,1<<MSG_KEY_DOWN+1<<MSG_KEY_UP)) {
      case MSG_KEY_DOWN:
        switch (arg1) {
          case CH_SHIFT_ESC:
          case CH_ESC:
            APP_QUIT=TRUE;
          default:
            begin=KbdMsEvtTime;
            DCFill;
            
            break;
        }
        break;
      case MSG_KEY_UP:
        break;
    }
  }

  draw_saver=NULL;
  DCFill;

} catch
  PutExcept;

//  RegWrite(reg_key,"F64 best_score=%5.4f;\n",best_score);

//while (ch!=CH_ESC && ch!=CH_SHIFT_ESC && !APP_QUIT);
//}

Exit;