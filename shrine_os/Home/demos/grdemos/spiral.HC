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

/*spiral.HC
  Description:
      Generates a spiral.
*/
Cd(__DIR__);;

#define PARTICLE_MAX GR_WIDTH*GR_HEIGHT

#include "grdefs"

U64 i;

#define SPIRAL_TURN_FACTOR 0.1

U64 pc=0;

F64 px,py,pz;

U64 COLORS[3]={WHITE,LTPURPLE,YELLOW};

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  for(i=0;i<pc;i++)
  {
    dc->color=p_arr[i].color;
    GrPlot(dc,p_arr[i].x,p_arr[i].y);
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
  p_deinit(&p_arr,PARTICLE_MAX);
 
  F64 radius=0,
       angle=0,
           x,y;

  for (i=0;i<PARTICLE_MAX;i++)
  {
    //Ppolar coordinates to cartesian coordinates
    x=WIDTH_CENTER+radius*Cos(angle);
    y=HEIGHT_CENTER+radius*Sin(angle);

    //Within screen bounds
    if (x>=0&&x<WIDTH&&y>=0&&y<HEIGHT) {
      p_arr[pc].x=x;
      p_arr[pc].y=y;
      p_arr[pc].color=COLORS[RandU16%3];

      pc++;
    }

    radius+=SPIRAL_TURN_FACTOR;
    angle+=0.2;
  }
}

U0 MS_L_DOWN(){}
U0 MS_L_UP(){}
U0 MS_MOVE(){}
U0 MS_R_DOWN(){}
U0 MS_R_UP(){}
U0 KEY_DOWN(){}

#define MOUSE_TRAP FALSE

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);
