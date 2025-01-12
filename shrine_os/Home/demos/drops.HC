/*
  The MIT License(MIT)
  Copyright(c), Tobey Peters, https://github.com/tobeypeters
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
  and associated documentation files (the "Software"), to deal in the Software without restriction,
  including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
  subject to the following conditions:
  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*drops.HC
  Description:
      Generates raindrops and stuff.
*/
#define DROPS_NUM  0x2000
#define TILES_NUM  0x04b0

class Drop
{
  I32 x,y;
} drops[DROPS_NUM];

CDC *cdc=DCNew(GR_WIDTH,GR_HEIGHT);

//Change to #define?
U8 *disp_str=MStrPrint("The Legend of Terry"),
            l=StrLen(disp_str);


//Normally I wouldn't declare everything global like this.
//But, declaring them 30times a second isn't needed.
U64 d,i,j,x1,y1,x2,y2,cur_drop,c1,c2,x0,y0,dco,scg,sch,sci,
    w=GR_WIDTH,h=GR_HEIGHT-FONT_HEIGHT,
   cx=w/2,cy=h/2,
  ctx=TEXT_COLS*FONT_WIDTH/2,
  cty=TEXT_ROWS*FONT_WIDTH/2,
   fw=FONT_WIDTH,
   fh=FONT_HEIGHT,
   pc=4000;

U0 drawGrid()
{
  cdc->color=YELLOW;

  i=x1=y1=0;
  for (;x1<w;x1+=16) GrLine(cdc,x1,y1,x1,h,2,2);

  i=x1=y1=0;
  for (;y1<h;y1+=16) GrLine(cdc,x1,y1,w,y1,2,2);
}
U0 drawBox(U64 x,U64 y,U64 w,U64 h,U64 t=1,U64 c=WHITE)
{
  U64 ot=cdc->thick,
      oc=cdc->color;

  cdc->thick=t;cdc->color=c;

  GrBorder(cdc,x,y,x+w,y+h);

  cdc->thick=ot;cdc->color=oc;
}
U0 drawHUD()
{
  //This will be drastically changed
  U64 hsx=w*.75;

  cdc->color=LTRED;
  GrPrint(cdc,hsx,fh,  "��LIFE��");

  drawBox(100,100,100,20,2,LTGREEN);

  GrArrow3(cdc,100,100,0,90,90,0);
}
U0 dispInfo()
{
  cdc->color=LTRED;
  GrPrint(cdc,fw,fh,
          "GR_WIDTH\nGR_HEIGHT: %dx%d",GR_WIDTH,GR_HEIGHT);
  GrPrint(cdc,fw,fh*3,
          "Fs->pix_width\nFs->pix_height:%dx%d",Fs->pix_width,Fs->pix_height);
  GrPrint(cdc,fw,fh*5,
          "TEXT_COLS\nTEXT_ROWS: %dx%d",TEXT_COLS,TEXT_ROWS);
  GrPrint(cdc,fw,fh*7,"FPS: %2tf",winmgr.fps);
  GrPrint(cdc,fw,fh*8,"FONT_HEIGHT\nFONT_WIDTH; %dx%d",fh,fw);
  GrPrint(cdc,fw,fh*10,"TILES_NUM: 40x30 : %d",TILES_NUM);
}
/*U0 RGB2C(U64 red, U64 green, U64 blue) {
  CBGR48 col=0;

  col.r=ClampI64(red,0,63)<<10;
  col.g=ClampI64(green,0,63)<<10;
  col.b=ClampI64(blue,0,63)<<10;

  return col;
}*/
U0 pinski()
{//sierpinski triangle
  x1=x2=w/2;
  y1=y2=0;

  cdc->color=LTGREEN;

  for(i=0;i<pc;i++)
  {
    d=RandU16&3;
    switch (d)
    {
      case 0:
        x1=(x2+w/2)/2;
        y1=y2/2;

        break;
      case 1:
        x1=(x2+40)/2;
        y1=(y2+h-40)/2;

        break;
      default:
        x1=(x2+w-40)/2;
        y1=(y2+h-40)/2;
    }

    if (i<(pc*.6)) cdc->color=GREEN;
    else cdc->color=WHITE;
    GrPlot(cdc,x1,y1);

    x2=x1; y2=y1;
  }
}

U0 DrawIt(CTask *task,CDC *dc)
{
  cdc=dc;

  pinski;

  if (Bt(kbd.down_bitmap,scg)) {
    dc->color=PURPLE;
    GrRect(dc,cx-2,cy-2,5,5);

    drawGrid;
  }

  if (Bt(kbd.down_bitmap,sch)) drawHUD;
  if (Bt(kbd.down_bitmap,sci)) dispInfo;

  dc->color=WHITE;
  for (i=0;i<DROPS_NUM;i++)
    if (drops[i].y>=0 && GrPeek(dc,drops[i].x,drops[i].y)==BLACK)
      GrPlot(dc,drops[i].x,drops[i].y);

  cdc->color=ROP_EQU;
  dc->flags|=DCF_NO_TRANSPARENTS;
  GrBlot(cdc,-task->pix_left-task->scroll_x,
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
	  if (GrPeek(cdc,x0,y0+1)==BLACK)
	    y1++;
	  else {
	    c1=GrPeek(cdc,x0+1,y0);
	    c2=GrPeek(cdc,x0-1,y0);

	    if (c1==BLACK&&c2!=BLACK)
	      x1++;
	    else if (c2==BLACK&&c1!=BLACK)
	      x1--;
	    else if (c1==BLACK&&c2==BLACK) {
	      c1=GrPeek(cdc,x0+1,y0+1);
	      c2=GrPeek(cdc,x0-1,y0+1);
	      if ((c1==BLACK&&c2!=BLACK)||(RandI16>=0))
		x1++;
	      else
		x1--;
	    }

	    if (GrPeek(cdc,x1,y1+1)==BLACK)  y1++;
	  }
	  if (GrPeek(cdc,x0,y0)==WHITE) {
	    cdc->color=BLACK;
	    GrPlot(cdc,x0,y0);
	  }
	  cdc->color=WHITE;
	  GrPlot(cdc,x1,y1);
	  drops[i].x=x1;
	  drops[i].y=y1;
	}
      }
    }
    Sleep(20);
  }
}

U0 Init()
{
  I64 i;
  MemSet(drops,0,sizeof(drops));
  for (i=0;i<DROPS_NUM;i++)
    drops[i].y=-I32_MAX;
}

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
WinBorder; WinMax;
DocCursor; DocClear;

Init;

scg=Char2ScanCode('g');
sch=Char2ScanCode('h');
sci=Char2ScanCode('i');

//Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",mp_cnt-1);
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
}
catch
  PutExcept;

cdc=NULL;
DCDel(cdc);

SettingsPop;
MenuPop;
