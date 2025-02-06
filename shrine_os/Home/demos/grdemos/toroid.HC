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

/*module.HC
  Description:
      Graphics module template.
*/
Cd(__DIR__);;

#define MAJOR_RADIUS 1.5
#define MINOR_RADIUS 0.5
#define RESOLUTION 100
#define DIM 128

#define PARTICLE_MAX RESOLUTION*RESOLUTION

#include "grdefs"

U64 pc=0,sx,sy,color;

PARTICLE pb;

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  for (ita=0;ita<pc;ita++)
  {
    pp=&p_arr[ita];

    // Apply rotation
    rot_plot(pp);
    
    // Project to screen space
    sx=(pp->x*WIDTH/4)+WIDTH_CENTER;
    sy=(pp->y*HEIGHT/4)+HEIGHT_CENTER;

    // Set color (gradient effect based on z-depth)
    dc->color=MapI64(pp->z,-MAJOR_RADIUS-MINOR_RADIUS,MAJOR_RADIUS+MINOR_RADIUS,0,15);

    GrPlot(dc,pp->x,pp->y);
  }
}

U0 AnimateTask(I64)
{
  while (TRUE) {
    Sleep(20);
  }
}

U0 Init()
{
  //p_deinit(&p_arr,PARTICLE_MAX);
  //p_init(&p_arr,PARTICLE_MAX);
  F64 u,v;
  for (ita=0;ita<RESOLUTION;ita++)
  {
    u=2*ã*ita/RESOLUTION;
    for (itb=0;itb<RESOLUTION;itb++)
    {
      v=2*ã*itb/RESOLUTION;
      p_arr[pc].x=(MAJOR_RADIUS+MINOR_RADIUS*Cos(v))*Cos(u);
      p_arr[pc].y=(MAJOR_RADIUS+MINOR_RADIUS*Cos(v))*Sin(u);
      p_arr[pc].z=MINOR_RADIUS*Sin(v);
      pc++;
    }
  }
}

U0 MS_L_DOWN(){}
U0 MS_L_UP(){}
U0 MS_MOVE()
U0 MS_MOVE_DOWN()
{
  rotation_x+=(ms.pos.y-prev_mouse_y)*0.01;
  rotation_y+=(ms.pos.x-prev_mouse_x)*0.01;
}
U0 MS_R_DOWN(){}
U0 MS_R_UP(){}
U0 KEY_DOWN(){}


U0 MS_L_DOWN(){}
U0 MS_L_UP(){}
U0 MS_MOVE(){}
U0 MS_MOVE_LDOWN(){}
U0 MS_MOVE_RDOWN(){}
U0 MS_R_DOWN(){}
U0 MS_R_UP(){}
U0 KEY_DOWN(){}


#define MOUSE_TRAP TRUE

//Update mouse postion values,
//even when mouse button not pressed.
#define MOUSE_NODOWN FALSE

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);
