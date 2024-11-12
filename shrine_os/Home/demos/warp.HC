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

/*warp.HC
  Description:
      Generates a "starfield" and applies a "warp" effect.
*/

#define WIDTH GR_WIDTH
#define HEIGHT GR_HEIGHT

#define STAR_COUNT 500 //Number of stars
#define STREAK_LEN 4

class Star
{
  F64  x,y, //Current position of the star
     angle, //Angle of movement from the center
     speed, //Speed of the star
  distance; //Distance from the center

  F64 color,
      px,py;
} stars[STAR_COUNT];

Star *p=NULL;

U8 COLORS[4]={YELLOW,RED,WHITE,LTCYAN};

U0 InitStar(U64 i)
{
  p=&stars[i];
  p->px=p->x=WIDTH/2;
  p->py=p->y=HEIGHT/2;
  p->angle=(RandU16%360)*(ã/180.0); //Random angle in radians
//  p->speed=(RandU16%50)/50.0+0.5;   //Random speed
  p->speed=Max(RandU16%50,1);       //Random speed
  p->distance=0;                    //Start at the center
  p->color=RandU16%4;
}
U0 Init()
{
  U64 i;

  for (i=0;i<STAR_COUNT;i++) InitStar(i);
}
U0 updateStars()
{
  U64 i;

  for (i=0;i<STAR_COUNT;i++)
  {
    p=&stars[i];

    // Increase the distance, which simulates moving outward
    p->distance+=p->speed;

    p->px=p->x; p->py=p->y;

    // Update x and y based on angle and distance from the center
    p->x=WIDTH/2+Cos(p->angle)*p->distance;
    p->y=HEIGHT/2+Sin(p->angle)*p->distance;

    //Chaotic version
    //p->x=(WIDTH/2+RandU16%16)+Cos(p->angle)*p->distance;
    //p->y=(HEIGHT/2+RandU16%16)+Sin(p->angle)*p->distance;

    // Reset star if it goes out of bounds
    if (p->x<0||p->x>WIDTH-1||
        p->y<0||p->y>HEIGHT-1) InitStar(i);
  }
}
U0 displayStarfield(CDC *dc)
{
  U64 i,j,ld,rd,ud,dd,t;

  U64 test=20;

  for (i=0;i<STAR_COUNT;i++) {
    p=&stars[i];

//Debug start
    dc->color=YELLOW;
//    GrPrint(dc,FONT_WIDTH,FONT_HEIGHT,"%d",test); //WORKS
    GrPrint(dc,FONT_WIDTH,FONT_HEIGHT,"%d",ToI64(p->x)); //DISPLAYS GARBAGE
//Debug end

    dc->color=COLORS[p->color];
    GrPlot(dc,p->x,p->y);

    ld=p->px-p->x; rd=p->x-p->px;
    ud=p->py-p->y; dd=p->y-p->py;

    t=STREAK_LEN+RandU16%4;

    if (ld<t||rd<t)
      if (ud<t||dd<t)
        GrLine(dc,p->x,p->y,p->px,p->py);    
  }
}
U0 DrawIt(CTask *task,CDC *dc)
{
  displayStarfield(dc);
//  updateStars;
}
U0 AnimateTask(I64)
{
  while (TRUE)
  {
    updateStars;
    Sleep(30);
  }
}

U0 Warp()
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
}

Warp;
