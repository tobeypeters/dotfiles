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
    dc->color=p_arr[ita].color;
    GrRect(dc,p_arr[ita].x,p_arr[ita].y,2,2);
  }
}

U0 AnimateTask(I64)
{
  while (TRUE) {
    for (ita=0;ita<PARTICLE_MAX;ita++)
    {
      dx=p_arr[ita].x-vortex.x;
      dy=p_arr[ita].y-vortex.y;

      vx=-dy*vortex.speed;
      vy=dx*vortex.speed;

      factor=1/(1+D3DistSqr(&p_arr[ita],&vortex)/vortex.scale);

      p_arr[ita].x+=(vx-p_arr[ita].vx)*factor+p_arr[ita].vx*dt;
      p_arr[ita].y+=(vy-p_arr[ita].vy)*factor+p_arr[ita].vy*dt;
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
    p_arr[ita].x=RandU16%WIDTH;
    p_arr[ita].y=RandU16%HEIGHT;
    p_arr[ita].vx=(Rand%F64_MAX)*2-1; // Random velocity between -1.0 and 1.0
    p_arr[ita].vy=(Rand%F64_MAX)*2-1;
    p_arr[ita].color=RandU16%15;
  }
}

U0 MS_L_DOWN(){}
U0 MS_L_UP(){}
U0 MS_MOVE(){}
U0 MS_MOVE_LDOWN(){}
U0 MS_MOVE_RDOWN(){}
U0 MS_R_DOWN(){}
U0 MS_R_UP(){}
U0 KEY_DOWN(){}

#define MOUSE_TRAP FALSE

//Update mouse postion values,
//even when mouse button not pressed.
#define MOUSE_NODOWN FALSE

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);
