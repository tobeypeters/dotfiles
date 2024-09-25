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

CDC *cur_dc;

U0 DrawIt(CTask *task,CDC *dc)
{
  U64 w=Fs->pix_width,
      h=Fs->pix_height,
     cx=w/2,cy=h/2,
    ctx=TEXT_COLS*FONT_WIDTH/2,
    cty=TEXT_ROWS*FONT_WIDTH/2;

  static U8 *disp_str=MStrPrint("Benjamin"),
            *disp_rstr=MStrPrint("%s",rev_str(disp_str)),
            l=StrLen(disp_str);

  U64 ctxo=ctx-((l/2)*FONT_WIDTH),
      ctyo=cty-((l/2)*FONT_HEIGHT);

  dc->color=WHITE;
  GrPrint(dc,ctxo,ctyo,disp_str);
  GrPrint(dc,ctxo,ctyo+(l*FONT_HEIGHT)-FONT_HEIGHT,disp_rstr);
  GrVPrint(dc,ctxo,ctyo,disp_str);
  GrVPrint(dc,ctxo+(l-1)*FONT_WIDTH,ctyo,disp_rstr);

  dc->color=LTRED;
  GrPrint(dc,10,50,
          "%dx%d",GR_WIDTH,GR_HEIGHT);
  GrPrint(dc,10,60,
          "%dx%d",Fs->pix_width,Fs->pix_height);
  GrPrint(dc,10,70,
          "%dx%d",TEXT_COLS,TEXT_ROWS);
  GrPrint(dc,10,80,"FPS: %2tf",winmgr.fps);

  GrLine(dc,cx-1,cy-1,cx-4,cy-4);
  GrLine(dc,cx+1,cy-1,cx+4,cy-4);

  dc->color=LTGREEN;
  GrPlot(dc,cx,cy);

  I64 i;
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
  I64 i,j,cur_drop=0,c1,c2,x0,y0,x1,y1,w,h;
  while (TRUE) {
    w=Fs->parent_task->pix_width;
    h=Fs->parent_task->pix_height;

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
  SettingsPush; //See $LK,"SettingsPush",A="MN:SettingsPush"$
  AutoComplete;
  WinBorder;
  WinMax;
  DocCursor;
  DocClear;
  cur_dc=DCNew(GR_WIDTH,GR_HEIGHT);
  Init;
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
