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

#define SPIRAL_TURN_FACTOR 0.1

U64 pc=0;

F64 px,py,pz;

U64 COLORS[3]={WHITE,LTPURPLE,YELLOW};

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  p_plot(dc,&p_arr,pc);
}

U0 AnimateTask(I64){}

U0 Init()
{
  p_deinit(&p_arr,PARTICLE_MAX);
 
  F64 radius=0,
       angle=0,
           x,y;

  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[pc];
    //Ppolar coordinates to cartesian coordinates
    x=WIDTH_CENTER+radius*Cos(angle);
    y=HEIGHT_CENTER+radius*Sin(angle);

    //Within screen bounds
    if (x>=0&&x<WIDTH&&y>=0&&y<HEIGHT) {
      pp->x=x;
      pp->y=y;
      pp->color=COLORS[RandU16%3];

      pc++;
    }

    radius+=SPIRAL_TURN_FACTOR;
    angle+=0.2;
  }
}

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);
