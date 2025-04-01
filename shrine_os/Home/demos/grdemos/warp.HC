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
      Generates a starfield warp effect.
*/
Cd(__DIR__);;

#define PARTICLE_MAX 500

#include "grdefs"

#define STREAK_LEN 4

F64 at; //Animate task sleep amount

Bool cf=FALSE; //Chaotic flag

U8 COLORS[4]={LTGREEN,WHITE,YELLOW,LTCYAN};

U64 o,cw=WIDTH_CENTER,ch=HEIGHT_CENTER;

PARTICLE cp,np;

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  dc->color=LTRED;
  GrPlot(dc,cw,ch);

  o=8;

  for (ita=0;ita<PARTICLE_MAX;ita++) {
    pp=&p_arr[ita];

    cp.x=pp->x; cp.y=pp->y;
    np.x=pp->px; np.y=pp->py;

    if (!(cw-o<=cp.x<=cw+o)||
        !(ch-o<=cp.y<=ch+o))
    {
      dc->color=COLORS[pp->color];
      GrPlot(dc,cp.x,cp.y);

//      Get the Euclidean distance between the current and previous points.
//      ll=Sqrt((np.x-cp.x)*(np.x-cp.x)+(np.y-cp.y)*(np.y-cp.y));

      if (D3Dist(&cp,&np)<=STREAK_LEN+RandU16%4)
        GrLine(dc,np.x,np.y,cp.x,cp.y);
    }
  }
}

U0 InitStar(PARTICLE *p)
{
  p->x=p->px=WIDTH_CENTER;
  p->y=p->py=HEIGHT_CENTER;
  p->z=p->pz=0;
  p->angle=(RandU16%360)*(M_PI/180); //Random angle in radians
//  p->speed=(RandU16%50)/50.0+0.5;   //Random speed
  p->speed=Max(RandU16%50,1);       //Random speed
  p->distance=0;                    //Start at the center
  p->color=RandU16%4;
}
U0 Init()
{
  at=30;

  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];
    InitStar(pp);
  }
}

U0 AnimateTask(I64)
{
  while (TRUE) {
    for (ita=0;ita<PARTICLE_MAX;ita++)
    {
      pp=&p_arr[ita];

      // Increase the distance, which simulates moving outward
      pp->distance+=pp->speed;

      pp->px=pp->x; pp->py=pp->y;

      if (cf)
      {
        //Chaotic version
        pp->x=(WIDTH/2+RandU16%16)+Cos(pp->angle)*pp->distance;
        pp->y=(HEIGHT/2+RandU16%16)+Sin(pp->angle)*pp->distance;
      }
      else
      {
        // Update x and y based on angle and distance from the center
        pp->x=WIDTH/2+Cos(pp->angle)*pp->distance;
        pp->y=HEIGHT/2+Sin(pp->angle)*pp->distance;
      }

      // Reset star if it goes out of bounds
      if (pp->x<0||pp->x>WIDTH-1||
        pp->y<0||pp->y>HEIGHT-1) InitStar(pp);
    }

    Sleep(at);
  }
}

U0 key_down()
{
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
KEY_DOWN=&key_down;

ANIMATE_TASK=TRUE;

Fs->win_inhibit|=WIG_DBL_CLICK;

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);
