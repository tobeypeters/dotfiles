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

/*mandelbulb.HC
  Description:
      Generates a spiral.
  Resources:
      https://en.wikipedia.org/wiki/Mandelbulb
*/
#define  WIDTH GR_WIDTH
#define HEIGHT GR_HEIGHT

#define CX WIDTH/2
#define CY HEIGHT/2
#define SPIRAL_TURN_FACTOR 0.1
#define MAX_POINTS WIDTH*HEIGHT

CD2 points[MAX_POINTS];

U64 pc=0;

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(BLACK);

  U64 i,color=0;

  F64 px,py,pz;

  for(i=0;i<pc;i++)
  {
    dc->color=color;

    GrPlot(dc,points[i].x,points[i].y);

//    color=MaxU64(1,(color+1)%16);
    color=RandU16%15;
  }
}

U0 Init()
{
  F64 radius=0,
       angle=0,
           x,y;

  U64 i;

  for (i=0;i<MAX_POINTS;i++)
  {
    //Ppolar coordinates to cartesian coordinates
    x=CX+radius*Cos(angle);
    y=CY+radius*Sin(angle);

    //Within screen bounds
    if (x>=0&&x<WIDTH&&y>=0&&y<HEIGHT) {
      points[pc].x=x;
      points[pc].y=y;
      pc++;
    }

    radius+=SPIRAL_TURN_FACTOR;
    angle+=0.2;
  }
}

MenuPush(
  "File {"
  "  Abort(,CH_SHIFT_ESC);"
  "  Exit(,CH_ESC);"
  "}"
  "Play {"
  "}"
);

SettingsPush;
AutoComplete;
WinBorder; WinMax;
DocCursor; DocClear;

Fs->draw_it=&DrawIt;

Init;

I64 arg1,arg2,sc;

Bool run=TRUE;
try {
  while (run) {
    sc=GetMsg(&arg1,&arg2,1<<MSG_KEY_DOWN);
    switch (sc) {
      case MSG_KEY_DOWN:
        if (arg1==CH_SHIFT_ESC||arg1==CH_ESC)
          run=FALSE;
    }
  }
} catch
  PutExcept;


SettingsPop;
MenuPop;
