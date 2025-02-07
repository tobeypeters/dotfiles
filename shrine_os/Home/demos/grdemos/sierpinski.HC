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

/*sierpinski.HC
  Description:
      Sierpinski triangle.
*/
Cd(__DIR__);;

#define PARTICLE_MAX 4000

#include "grdefs"

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  p_plot(dc,&p_arr,PARTICLE_MAX);
}

U0 AnimateTask(I64){}

U0 Init()
{
  p_deinit(&p_arr,PARTICLE_MAX);

  U64 x2,y2;

  x2=WIDTH_CENTER;
  y2=0;

  for(ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];

    d=RandU16&3;
    switch (d)
    {
      case 0:
        pp->x=(x2+WIDTH_CENTER)/2;
        pp->y=y2/2;

        break;
      case 1:
        pp->x=(x2+40)/2;
        pp->y=(y2+HEIGHT-40)/2;

        break;
      default:
        pp->x=(x2+WIDTH-40)/2;
        pp->y=(y2+HEIGHT-40)/2;
    }

    x2=pp->x;
    y2=pp->y;
    pp->color=GREEN;
  }
}

U0 MS_L_DOWN(){}
U0 MS_L_UP(){}
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
