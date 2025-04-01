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

/*voronoi.HC
  Description:
      Generates a voronoi diagram.
  Resources:
      https://en.wikipedia.org/wiki/Voronoi_diagram
*/
Cd(__DIR__);;

#define PARTICLE_MAX 10

#include "grdefs"

CDC *vor_dc=DCNew(WIDTH,HEIGHT);

U64 GetColor()
{
  U64 res;

  pick:
  res=RandU16%COLORS_NUM;

  if (I64InLst(res,0,8,15)) goto pick;
  return res;
}

F64 cur_time,delta_time,prev_time;

U0 GenVoronoi() {
  DCFill(vor_dc,GetColor);
  
  U64 minDist,dx,dy,dist,color;

  for (ita=0;ita<HEIGHT;ita++)
  {
    for (itb=0;itb<WIDTH;itb++)
    {
      minDist=WIDTH*HEIGHT;
      color=BLACK;
      for (itc=0;itc<PARTICLE_MAX;itc++)
      {
        pp=&p_arr[itc];
        dx=itb-pp->x;
        dy=ita-pp->y;
        dist=Dist(dx,dy);

        if (dist<minDist) {
          minDist=dist;
          color=pp->color;
        }
        vor_dc->color=color;
        GrPlot(vor_dc,itb,ita);
      }
    }
  }

  U64 x,y;
  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];

    vor_dc->color=WHITE;
    GrRegPoly(vor_dc,pp->x-2,pp->y-2,2,2,4);
    vor_dc->color=BLACK;
    GrFloodFill(vor_dc,pp->x-2,pp->y-2);
  }
}

U0 DrawIt(CTask *task,CDC *dc)
{
  GrBlot(dc,0,0,vor_dc);
}

F64 xx,yy;
U0 AnimateTask(I64)
{
  while (TRUE) {

    for (itc=0;itc<PARTICLE_MAX;itc++)
    {
      pp=&p_arr[itc];

      xx=pp->x+pp->vx*delta_time;
      yy=pp->y+pp->vy*delta_time;

      if (0<=xx&&xx<=WIDTH)
        pp->x=xx;
      else
        pp->vx*=-2;

      if (0<=yy&&yy<=HEIGHT)
        pp->y=yy;
      else
        pp->vy*=-2;
    }

    cur_time=tS;
    delta_time=cur_time-prev_time;
    prev_time=cur_time;   

    GenVoronoi;

    Sleep(120);
  }
}

U0 Init()
{
  F64 angle;

  delta_time=prev_time=0;

  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];

    pp->x=RandU16%WIDTH;
    pp->y=RandU16%HEIGHT;

    pp->color=GetColor;

    angle=Rand*2*M_PI;

    pp->vx=Cos(angle)*30;
    pp->vy=Sin(angle)*30;
  }

  GenVoronoi;
}

ANIMATE_TASK=TRUE;

Fs->win_inhibit|=WIG_DBL_CLICK;

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);

DCDel(vor_dc);
