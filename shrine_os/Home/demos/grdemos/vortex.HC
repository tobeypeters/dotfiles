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

/*vortex.HC
  Description:
      Creates a "vortex" effect.
  Resources:
      https://en.wikipedia.org/wiki/Vortex
*/
Cd(__DIR__);;

#define PARTICLE_MAX 1000

#include "grdefs"

PARTICLE vortex;

F64 dx,dy,vx,vy,
    factor,dt=0.016;

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];

    dc->color=pp->color;
    GrRect(dc,pp->x,pp->y,2,2);
  }
}

U0 AnimateTask(I64)
{
  while (TRUE) {
    for (itc=0;itc<PARTICLE_MAX;itc++)
    {
      pp=&p_arr[itc];

      dx=pp->x-vortex.x;
      dy=pp->y-vortex.y;

      vx=-dy*vortex.speed;
      vy=dx*vortex.speed;

      factor=1/(1+D3DistSqr(pp,&vortex)/vortex.scale);

      pp->x+=(vx-pp->vx)*factor+pp->vx*dt;
      pp->y+=(vy-pp->vy)*factor+pp->vy*dt;
    }

    Sleep(8);
  }
}

U0 Init()
{
  p_deinit(&p_arr,PARTICLE_MAX);

  vortex.x=WIDTH_CENTER;
  vortex.y=HEIGHT_CENTER,
  vortex.speed=1;
  vortex.scale=10;

  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];
    pp->x=RandU16%WIDTH;
    pp->y=RandU16%HEIGHT;
    pp->vx=(Rand%F64_MAX)*2-1; // Random velocity between -1.0 and 1.0
    pp->vy=(Rand%F64_MAX)*2-1;
    pp->color=RandU16%15;
  }
}

ANIMATE_TASK=TRUE;

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);
