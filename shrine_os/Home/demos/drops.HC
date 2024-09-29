U8 *rev_str(U8 *str)
{//Reverse a string.  I thought, TempleOS had one.
 //I can't find it. If there's one buried in the OS,
 //I'll get rid of this one.
 //I'm not using the normal swapping algorithm here.
  U64 l=StrLen(str)-1,i=0;
  U8 *st=CAlloc(sizeof(U8)*l);

  for (;i<=l;i++) *(st+i)=str[l-i];

  return st;
}

#define DROPS_NUM	0x2000

class Drop
{
  I32 x,y;
} drops[DROPS_NUM];

CDC *cur_dc=DCNew(GR_WIDTH,GR_HEIGHT);

//Change to #define?
U8  *disp_str=MStrPrint("Benjamin"),
//   *disp_rstr=MStrPrint("%s",rev_str(disp_str)),
            l=StrLen(disp_str);

//Normally I wouldn't declare everything global like this.
//But, declaring them 30times a second isn't needed.
U64 d,i,j,x1,y1,x2,y2,cur_drop,c1,c2,x0,y0, scg,
    w=GR_WIDTH,h=GR_HEIGHT-FONT_HEIGHT,
   cx=w/2,cy=h/2,
  ctx=TEXT_COLS*FONT_WIDTH/2,
  cty=TEXT_ROWS*FONT_WIDTH/2,
 ctxo=ctx-((l/2)*FONT_WIDTH),
 ctyo=cty-((l/2)*FONT_HEIGHT),
   fw=FONT_WIDTH,
   fh=FONT_HEIGHT,
   pc=40000;

U0 pinski(CDC *dc)
{//sierpinski triangle
  x1=x2=w/2;
  y1=y2=0;

  dc->color=LTGREEN;

  for(i=0;i<pc;i++)
  {
    d=RandU16&3;
    switch (d)
    {
      case 0:
        x1=(x2+w/2)/2;
        y1=(y2+0)/2;

        break;
      case 1:
        x1=(x2+40)/2;
        y1=(y2+h-40)/2;

        break;
      default:
        x1=(x2+w-40)/2;
        y1=(y2+h-40)/2;
    }

    if (i<(pc*.6)) dc->color=GREEN;
    else dc->color=WHITE;
//    dc->color=RandU16%COLORS_NUM;
    GrPlot(dc,x1,y1);

    x2=x1; y2=y1;
  }
}

U0 drawGrid(CDC *dc)
{
  U64 i,j;

  dc->color=YELLOW;

  i=x1=y1=0;
  for (;x1<w;x1+=16) {
//    GrPlot(dc,x1,y1);
    GrLine(dc,x1,y1,x1,h,2,2);
  }

  i=x1=y1=0;
  for (;y1<h;y1+=16) {
//    GrPlot(dc,x1,y1);
    GrLine(dc,x1,y1,w,y1,2,2);
  }
}

U0 DrawIt(CTask *task,CDC *dc)
{
  pinski(dc);

  if (Bt(kbd.down_bitmap,scg)) {
    dc->color=PURPLE;
    GrRect(dc,cx-2,cy-2,5,5);
    drawGrid(dc);
  }

  dc->color=WHITE;
  GrPrint(dc,ctxo+1,cty+1,"The Legend of\n Benjamin");
  dc->color=BROWN;
  GrPrint(dc,ctxo,cty,"The Legend of\n Benjamin");
/*  GrPrint(dc,ctxo,cty,disp_str);
  GrPrint(dc,ctxo,cty+(l*fh)-fh,disp_rstr);
  GrVPrint(dc,ctxo,cty,disp_str);
  GrVPrint(dc,ctxo+(l-1)*fw,cty,disp_rstr);*/

  dc->color=LTRED;
  GrPrint(dc,fw,fh,
          "%dx%d",GR_WIDTH,GR_HEIGHT);
  GrPrint(dc,fw,fh*2,
          "%dx%d",Fs->pix_width,Fs->pix_height);
  GrPrint(dc,fw,fh*3,
          "%dx%d",TEXT_COLS,TEXT_ROWS);
  GrPrint(dc,fw,fh*4,"FPS: %2tf",winmgr.fps);
  GrPrint(dc,fw,fh*5,"%dx%d",fh,fw);

//        "$$$$FG,%d$$$$Û",i;i++;

/*  GrLine(dc,cx-1,cy-1,cx-4,cy-4);
  GrLine(dc,cx+1,cy-1,cx+4,cy-4);

  dc->color=LTGREEN;
  GrPlot(dc,cx,cy);*/

  dc->color=WHITE;
  for (i=0;i<DROPS_NUM;i++)
//    if (drops[i].y>=0 && GrPeek(dc,drops[i].x,drops[i].y)==WHITE)
      GrPlot(dc,drops[i].x,drops[i].y);

  cur_dc->color=ROP_EQU;
  dc->flags|=DCF_NO_TRANSPARENTS;
  GrBlot(cur_dc,-task->pix_left-task->scroll_x,
	-task->pix_top-task->scroll_y,dc);
  dc->flags&=~DCF_NO_TRANSPARENTS;

}

U0 AnimateTask(I64)
{
  cur_drop=0;
  while (TRUE) {
    for (i=0;i<2;i++) {
      j=0;
      do {
	if (++cur_drop>=DROPS_NUM)
	  cur_drop=0;
	if (drops[cur_drop].y<0)
	  break;
	j++;
      } while (j<=DROPS_NUM);

      drops[cur_drop].x=RandU32%w;
      drops[cur_drop].y=0;
    }

    for (i=0;i<DROPS_NUM;i++) {
      if (drops[i].y>=0) {
	if (drops[i].y>=h-1)
	  drops[i].y=-I32_MAX;
	else {
	  x0=x1=drops[i].x;
	  y0=y1=drops[i].y;
	  if (GrPeek(cur_dc,x0,y0+1)==BLACK)
	    y1++;
	  else {
	    c1=GrPeek(cur_dc,x0+1,y0);
	    c2=GrPeek(cur_dc,x0-1,y0);
	    if (c1==BLACK && c2!=BLACK)
	      x1++;
	    else if (c2==BLACK && c1!=BLACK)
	      x1--;
	    else if (c1==BLACK && c2==BLACK) {
	      c1=GrPeek(cur_dc,x0+1,y0+1);
	      c2=GrPeek(cur_dc,x0-1,y0+1);
	      if (c1==BLACK && c2!=BLACK)
		x1++;
	      else if (c2==BLACK && c1!=BLACK)
		x1--;
	      else if (RandI16>=0)
		x1++;
	      else
		x1--;
	    }
	    if (GrPeek(cur_dc,x1,y1+1)==BLACK)
	      y1++;
	  }
	  if (GrPeek(cur_dc,x0,y0)==WHITE) {
	    cur_dc->color=BLACK;
	    GrPlot(cur_dc,x0,y0);
	  }
	  cur_dc->color=WHITE;
	  GrPlot(cur_dc,x1,y1);
	  drops[i].x=x1;
	  drops[i].y=y1;
	}
      }
    }
    Sleep(10);
  }
}

U0 Init()
{
  I64 i;
  MemSet(drops,0,sizeof(drops));
  for (i=0;i<DROPS_NUM;i++)
    drops[i].y=-I32_MAX;
}

U0 RainDrops()
{
  I64 ch,sc;
  MenuPush(
	"File {"
	"  Abort(,CH_SHIFT_ESC);"
	"  Exit(,CH_ESC);"
	"}"
	"Play {"
	"  Restart(,'\n');"
	"}"
	);
  SettingsPush;
  AutoComplete;
  WinBorder;
  WinMax;
  DocCursor;
  DocClear;
  Init;

  scg=Char2ScanCode('g');

  Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",,Fs);
  Fs->draw_it=&DrawIt;
  try {
    do
      switch (ch=GetKey(&sc)) {
	case '\n':
	  Init;
	  break;
      }
    while (ch!=CH_ESC && ch!=CH_SHIFT_ESC);
  } catch
    PutExcept;
  SettingsPop;
  MenuPop;
  DCDel(cur_dc);
}

RainDrops;
