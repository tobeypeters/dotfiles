U8 defBuf[255]="TempleOS";
U64 defLen=StrLen(defBuf),
     xunit=FONT_WIDTH,
     yunit=FONT_HEIGHT;

U0 randxy(U64 *x,U64* y)
{
  *x=Range(xunit,TEXT_COLS-defLen-xunit)*xunit;
  *y=Range(yunit,TEXT_ROWS-yunit)*yunit;
}

Bool dont=FALSE;

U64 x,y;
randxy(&x,&y);

U0 default_saver()
{ 
  if ((GetElapsedEvtTime%10)==0)
  {
    if (dont) randxy(&x,&y);
    dont=FALSE;
  }
  else dont=TRUE;

  DCFill(,BLACK);
  gr.dc->color=WHITE;
  GrPrint(,x,y,"TempleOS %d",cpu_structs[0].total_jiffies-winmgr.t->last_total_jiffies);
}

draw_saver=&default_saver;
