U0 ScrSaver(U8 *saver=DEFAULT_SAVER)
{
  Cd(__DIR__);;

  I64 elapsed=0;

restoredefault:
  if (FileFind(saver))
  {
    ExePrint("#include \"%s\"",saver);
  }
  else
  {
    AdamErr("Error: %s.HC not found ....\n",saver);

    if (saver==DEFAULT_SAVER)
    {
      AdamErr("       Screensaver has been terminated ...\n");
      return;
    }

    saver=DEFAULT_SAVER;

    goto restoredefault;
  }

/*  while (!SAVER_QUIT)
  {
    elapsed=GetElapsedEvtTime;

    if (elapsed>3)
      draw_saver();

    Sleep(10);
  }
*/
}

AdamLog("one\n");
ScrSaver;
AdamLog("two\n");
