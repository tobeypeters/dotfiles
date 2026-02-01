Cd(__DIR__);;

/*I64 begin=KbdMsEvtTime;
I64 elapsed=0;

U0 (*draw_saver)();

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
*/
Bool SaverPutKey(I64 ch,I64 sc)
{
  AdamLog('%c',ch);

//  begin=KbdMsEvtTime;
//  DCFill;

//  APP_QUIT=TRUE;

  return FALSE;
}

Bool SaverPutS(U8 *)
{
  return FALSE;
}

KeyDevAdd(&SaverPutKey,&SaverPutS,0x20000000,TRUE);

while (!APP_QUIT)
{
  Sleep(.1);
}

/*I64 arg1,arg2;
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
*/