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

#include "grdefs"

#define PARTICLE_MAX 1000

// Vortex class
PARTICLE vortex;

PARTICLE p_arr[PARTICLE_MAX];

F64 dx,dy,vx,vy,
    factor,dt=0.016;

U64 i,sch;

U0 DrawIt(CTask *task,CDC *dc)
{

  for (i=0;i<PARTICLE_MAX;i++)
  {
    dc->color=p_arr[i].color;
//    GrRect(dc,p_arr[i].x,p_arr[i].y,2,2);

//    GrPlot(dc,vortex.x,vortex.y);
    GrPlot(dc,p_arr[i].x,p_arr[i].y);
  }
}

U0 AnimateTask(I64)
{
  while (TRUE) {
    for (i=0;i<PARTICLE_MAX;i++)
    {
      dx=p_arr[i].x-vortex.x;
      dy=p_arr[i].y-vortex.y;

      vx=-dy*vortex.speed;
      vy=dx*vortex.speed;

      factor=1/(1+D3DistSqr(&p_arr[i],&vortex)/vortex.scale);

      p_arr[i].x+=(vx-p_arr[i].vx)*factor+p_arr[i].vx*dt;
      p_arr[i].y+=(vy-p_arr[i].vy)*factor+p_arr[i].vy*dt;
    }

    Sleep(8);
  }
}

U0 Init()
{
  p_deinit(&p_arr,PARTICLE_MAX);

  vortex.x=WIDTH_CENTER;
  vortex.y=HEIGHT_CENTER,
  vortex.speed=1;
  vortex.scale=10;

  for (i=0;i<PARTICLE_MAX;i++)
  {
    p_arr[i].x=RandU16%WIDTH;
    p_arr[i].y=RandU16%HEIGHT;
    p_arr[i].vx=(Rand%F64_MAX)*2-1; // Random velocity between -1.0 and 1.0
    p_arr[i].vy=(Rand%F64_MAX)*2-1;
    p_arr[i].color=RandU16%15;
  }
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

SettingsPop;
MenuPop;


