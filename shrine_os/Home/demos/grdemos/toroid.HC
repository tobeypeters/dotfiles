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

/*toroid.HC
  Description:
      Generates a toroid.
  Resources:
      https://en.wikipedia.org/wiki/Toroid
*/
Cd(__DIR__);;

#define RESOLUTION 100
#define PARTICLE_MAX RESOLUTION*RESOLUTION

#include "grdefs"

#define MAJOR_RADIUS 1.5
#define MINOR_RADIUS 0.5

U64 pc=0;

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  for (ita=0;ita<pc;ita++)
  {
    p_DUP(pp,&p_arr[ita]);

    //Apply rotation
    rot_plot(pp);
    
    dc->color=pp->color;
    //Project to screen space
    GrPlot(dc,(pp->x*WIDTH/4)+WIDTH_CENTER,
              (pp->y*HEIGHT/4)+HEIGHT_CENTER);
  }
}

Bool spinx=FALSE;
U0 AnimateTask(I64)
{
  while (TRUE) {
    //Spin right or left
    rotation_x+=spinx*0.1;
    rotation_y+=!spinx*0.1;

    if (rotation_x>M_PI||
        rotation_y>M_PI) {
      rotation_x=rotation_y=0;
    }

    Sleep(20);
  }
}

F64 x,y,z;

U64 COLORS[3]={LTBLUE,CYAN,WHITE};
U0 Init()
{
  F64 u,v;
  for (ita=0;ita<RESOLUTION;ita++)
  {
    u=2*M_PI*ita/RESOLUTION;
    for (itb=0;itb<RESOLUTION;itb++)
    {
      pp=&p_arr[pc];

      v=2*M_PI*itb/RESOLUTION;

      pp->x=(MAJOR_RADIUS+MINOR_RADIUS*Cos(v))*Cos(u);
      pp->y=(MAJOR_RADIUS+MINOR_RADIUS*Cos(v))*Sin(u);
      pp->z=MINOR_RADIUS*Sin(v);
      pp->color=COLORS[RandU16%3];

      pc++;
    }
  }
  pc--;
}

ANIMATE_TASK=TRUE;

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);
