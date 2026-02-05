/* This is all crap code

::: Patch starts here

  U8 *SAVER_PATH="::/Home/patchos";

  Bool SCREENSAVER_ENABLED=FALSE;

  U8 *DEFAULT_SAVER="default.HC";

  U0 (*draw_saver)();

  I64 BeginElapsedEvtTime=0;
  U64 GetElapsedEvtTime() return (GetTSC-BeginElapsedEvtTime)/cnts.time_stamp_freq;

  Bool SAVER_QUIT=FALSE;

  Bool SaverPutKey(I64 ch,I64 sc)
  {

    if (SCREENSAVER_ENABLED)
    {
      SCREENSAVER_ENABLED=FALSE;
      BeginElapsedEvtTime=KbdMsEvtTime;

      Del("::/Home/del.HC");

      DCFill;
    }

    WALL_DEBUG_VAL=ch;

    return FALSE;
  }

  Bool SaverPutS(U8 *) return FALSE;

  KeyDevAdd(&SaverPutKey,&SaverPutS,0xA0000000);

  //Screensaver end: Temporarily inside here

::: Patch ends here

*/

/*
U0 ScrSaver(U8 *saver=DEFAULT_SAVER)
{
  Fs->display_flags=0;
//  Cd(__DIR__);;
  Cd(SAVER_PATH);

  I64 elapsed=0;

restoredefault:
  if (FileFind(saver))
  {
    ExePrint("#include \"%s\"",saver);
  }
  else
  {
    AdamErr("Error: %s.HC not found ....\n",saver);

    if (saver==DEFAULT_SAVER)
    {
      AdamErr("       Screensaver has been terminated ...\n");
      return;
    }

    saver=DEFAULT_SAVER;

    goto restoredefault;
  }

  while (!SAVER_QUIT)
  {
    elapsed=GetElapsedEvtTime;

    if (elapsed>3)
    {
      SCREENSAVER_ENABLED=TRUE;
      draw_saver();
    }

    Sleep(10);
  }
}

AdamLog("one\n");
ScrSaver;
AdamLog("two\n");
*/