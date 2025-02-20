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

#define PARTICLE_MAX 20

#include "grdefs"

CDC *vor_dc;

CDC *GenVoronoi() {
  CDC *dc=DCNew(WIDTH,HEIGHT);
  
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
        dc->color=color;
        GrPlot(dc,itb,ita);
      }
    }
  }

  U64 x,y;
  dc->color=WHITE;
  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];

    dc->color=WHITE;
    GrRegPoly(dc,pp->x-2,pp->y-2,2,2,4);
    dc->color=BLACK;
    GrFloodFill(dc,pp->x-2,pp->y-2);
  }

  return dc;
}

U0 DrawIt(CTask *task,CDC *dc)
{
  vor_dc->flags|=DCF_NO_TRANSPARENTS;
  GrBlot(dc,0,0,vor_dc);
}

U0 AnimateTask(I64)
{
  while (TRUE) {
    Sleep(20);
  }
}
U0 Init()
{
  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];

    pp->x=RandU16%WIDTH;
    pp->y=RandU16%HEIGHT;
    pp->color=MaxI64(1,RandU16%COLORS_NUM);
  }

  vor_dc=GenVoronoi;
}

U0 MS_L_DOWN(){}
U0 MS_L_UP(){}
U0 MS_MOVE(){}
U0 MS_MOVE_LDOWN(){}
U0 MS_MOVE_RDOWN(){}
U0 MS_R_DOWN(){}
U0 MS_R_UP(){}
U0 KEY_DOWN(){}

#define ANIMATE_TASK FALSE

#define MOUSE_TRAP FALSE

//Update mouse postion values,
//even when mouse button not pressed.
#define MOUSE_NODOWN FALSE

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);

DCDel(vor_dc);
