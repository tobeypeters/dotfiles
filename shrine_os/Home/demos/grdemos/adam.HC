I64 begin=KbdMsEvtTime;
I64 elapsed=0;

U8 reg_saver[255];
U0 (*draw_saver)();

U8 defBuf[255]="TempleOS";
U64 defLen=StrLen(defBuf);
U0 randxy(U64 *x,U64* y)
{
  *x=Range(,TEXT_COLS-defLen+4)*FONT_WIDTH;
  *y=Range(,TEXT_ROWS-4)*FONT_HEIGHT;
}

U64 x=2,y=2;

//RegDft("TempleOS/FlapBat","F64 best_score=9999;\n");
//RegExe("TempleOS/FlapBat");

U64 GetElapsedEvtTime() return (GetTSC-begin)/cnts.time_stamp_freq;

Bool dont=FALSE;

U0 default_saver()
{ 
  if ((GetElapsedEvtTime%10)==0)
  {
    if (dont) randxy(&x,&y);
    dont=FALSE;
  }
  else dont=TRUE;

  DCFill(,LTGREEN);
  GrPrint(,x,y,"TempleOS %d",elapsed);
}

draw_saver=&default_saver;

Bool APP_QUIT=FALSE;

U0 AnimateTask(I64)
{
  while (!APP_QUIT)
  {
    elapsed=GetElapsedEvtTime;

//    if (elapsed>3)
//      begin=KbdMsEvtTime;
//    else
      draw_saver();

    Sleep(100);
  }
}

SettingsPush;
WinBorder;WinMax;
Fs->animate_task=Spawn(&AnimateTask,NULL,"saver_animate",,Fs);

I64 arg1,arg2;
U0 msg_loop(){
try {
  while (!APP_QUIT) {
    switch (GetMsg(&arg1,&arg2,1<<MSG_KEY_DOWN+1<<MSG_KEY_UP)) {
      case MSG_KEY_DOWN:
        switch (arg1) {
          case CH_SHIFT_ESC:
          case CH_ESC:
            APP_QUIT=TRUE;
            goto done;
        }
        break;
      case MSG_KEY_UP:
        break;
    }
  }

done:
  draw_saver=NULL;
  DCFill;

} catch
  PutExcept;

//  RegWrite("TempleOS/screensaver","F64 best_score=%5.4f;\n",best_score);

//while (ch!=CH_ESC && ch!=CH_SHIFT_ESC && !APP_QUIT);
}

msg_loop;
SettingsPop;
