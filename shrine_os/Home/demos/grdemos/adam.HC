I64 begin=KbdMsEvtTime;
I64 elapsed=0;


//(GetTSC-last_event)/cnts.time_stamp_freq
U0 AnimateTask(I64)
{
  while (TRUE)
  {
    elapsed=(GetTSC-begin)/cnts.time_stamp_freq;

    if (elapsed>3)
      begin=KbdMsEvtTime;

    Sleep(100);
  }
}

U64 x=FONT_WIDTH*4,
    y=FONT_HEIGHT*20;
U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,LTGREEN);
  GrPrint(dc,x,y,"%d",elapsed);
}

SettingsPush; //See $LK,"SettingsPush",A="MN:SettingsPush"$
WinBorder;WinMax;
Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",,Fs);
Fs->draw_it=&DrawIt;
while (ch!=CH_ESC && ch!=CH_SHIFT_ESC && !APP_QUIT);

SettingsPop;
