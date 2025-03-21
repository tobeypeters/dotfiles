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

/*mystify.HC
  Description:
      Generates a mystify effect like the old school Windows screensaver.
*/
Cd(__DIR__);;

#define NUM_GROUPS 2
#define NUM_LINES 5
#define POINTS_PER_LINE 4
#define GAP 3

#define PARTICLE_MAX NUM_GROUPS*POINTS_PER_LINE

#include "grdefs"

#define LINE_SPACING 5

U8 colors[2]={LTGREEN,WHITE};

U64 lgoff=0,loff=3;
U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  for (ita=0;ita<NUM_GROUPS;ita++)
  {
    dc->color=colors[ita];

    lgoff=(ita*POINTS_PER_LINE);
    for (itb=0;itb<NUM_LINES;itb++)
    {
      loff=GAP*itb;
      for (itc=0;itc<POINTS_PER_LINE-1;)
      {
        pp=&p_arr[itc+lgoff];ppp=&p_arr[++itc+lgoff];
        GrLine(dc,pp->x+loff,pp->y+loff,ppp->x+loff,ppp->y+loff);
      }

      pp=&p_arr[lgoff];
      GrLine(dc,pp->x+loff,pp->y+loff,
        ppp->x+loff,ppp->y+loff);
    }
  }
}

U0 AnimateTask(I64)
{
  while (TRUE) {

    for (ita=0;ita<PARTICLE_MAX;ita++)
    {
      pp=&p_arr[ita];
      pp->x+=pp->dx;
      pp->y+=pp->dy;

      if (pp->x<=0||pp->x>=WIDTH)
        pp->dx=-pp->dx;
      if (pp->y<=0||pp->y>=HEIGHT)
        pp->dy=-pp->dy;
    }

    Sleep(20);
  }
}

U64 Init3() return RandU16%5+1;
Bool Init2() {
  if (RandU16%2==0) return 1;
  else return -1;
}

U0 Init()
{
  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];

    pp->x=RandU16%WIDTH;
    pp->y=RandU16%HEIGHT;

    pp->dx=Init3*Init2;
    pp->dy=Init3*Init2;
  }
}

ANIMATE_TASK=TRUE;

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);
