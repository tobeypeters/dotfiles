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

#define MW WIDTH/2
#define MH HEIGHT/2

#define STAR_COUNT 500 //Number of stars
#define STREAK_LEN 4

class Star
{
  CD3 c,p;   //Current and previous position of the star

  F64 angle, //Angle of movement from the center
      speed, //Speed of the star
   distance, //Distance from the center
      color;

} stars[STAR_COUNT];

Star *p=NULL;

U8 COLORS[4]={LTGREEN,WHITE,YELLOW,LTCYAN};

F64 at=30; //Animate task sleep amount

Bool cf=FALSE; //Chaotic flag

U0 InitStar(U64 i)
{
  p=&stars[i];
  p->p.x=p->c.x=MW;
  p->p.y=p->c.y=MH;
  p->p.z=p->c.z=0;
  p->angle=(RandU16%360)*(ã/180); //Random angle in radians
//  p->speed=(RandU16%50)/50.0+0.5;   //Random speed
  p->speed=Max(RandU16%50,1);       //Random speed
  p->distance=0;                    //Start at the center
  p->color=RandU16%4;
}
U0 Init()
{
  U64 i; at=30;

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

    p->p.x=p->c.x; p->p.y=p->c.y;

    if (cf)
    {
      //Chaotic version
      p->c.x=(WIDTH/2+RandU16%16)+Cos(p->angle)*p->distance;
      p->c.y=(HEIGHT/2+RandU16%16)+Sin(p->angle)*p->distance;
    }
    else
    {
      // Update x and y based on angle and distance from the center
      p->c.x=WIDTH/2+Cos(p->angle)*p->distance;
      p->c.y=HEIGHT/2+Sin(p->angle)*p->distance;
    }

    // Reset star if it goes out of bounds
    if (p->c.x<0||p->c.x>WIDTH-1||
        p->c.y<0||p->c.y>HEIGHT-1) InitStar(i);
  }
}
U0 displayStarfield(CDC *dc)
{
  CD3 cp,np;

  U64 i,o;

  dc->color=LTRED;
  GrPlot(dc,MW,MH);

  o=8;

  for (i=0;i<STAR_COUNT;i++) {
    p=&stars[i];

    cp.x=p->c.x; cp.y=p->c.y;
    np.x=p->p.x; np.y=p->p.y;

    if (!(MW-o<=cp.x<=MW+o)||
        !(MH-o<=cp.y<=MH+o))
    {
      dc->color=COLORS[p->color];
      GrPlot(dc,cp.x,cp.y);

//      Get the Euclidean distance between the current and previous points.
//      ll=Sqrt((np.x-cp.x)*(np.x-cp.x)+(np.y-cp.y)*(np.y-cp.y));

      if (D3Dist(&cp,&np)<=STREAK_LEN+RandU16%4)
        GrLine(dc,np.x,np.y,cp.x,cp.y);
    }
  }
}
U0 DrawIt(CTask *task,CDC *dc)
{
  displayStarfield(dc);
}
U0 AnimateTask(I64)
{
  while (TRUE)
  {
    updateStars;
    Sleep(at);
  }
}

ADocClear;

I64 ch,sc;
MenuPush(
  "File {"
  "  Abort(,CH_SHIFT_ESC);"
  "  Exit(,CH_ESC);"
  "}"
  "Play {"
  "  Restart(,'\n');"
  "  Slower(,,SC_CURSOR_RIGHT);"
  "  Faster(,,SC_CURSOR_LEFT);"
  "}"
);

SettingsPush;
AutoComplete;
WinBorder; WinMax;
DocCursor; DocClear;

Init;

//Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",,Fs);
Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",mp_cnt-1);
Fs->draw_it=&DrawIt;

try {
  do
    switch (ch=GetKey(&sc)) {
      case '\n':
        Init;
        break;
    default:
      //Adam("\"%d\n\";",sc.u8[0]);

      switch (sc.u8[0]) {
        case 46:
          cf=!cf;
          break;
        case 75:
          at-=10;
          break;
        case 77:
          at+=10;
      }
      at=Clamp(at,1.0,100.0);
    }
  while (ch!=CH_ESC && ch!=CH_SHIFT_ESC);
}
catch
  PutExcept;

SettingsPop;
MenuPop;
