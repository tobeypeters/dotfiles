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
#define POINTS_PER_LINE 5
#define GAP 3

#define PARTICLE_MAX NUM_GROUPS*POINTS_PER_LINE

#include "grdefs"

U8 colors[2]={BROWN,LTRED};

U64 lgoff,loff;
U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  for (ida=0;ida<NUM_GROUPS;ida++)
  {
    dc->color=colors[ida];

    lgoff=(ida*POINTS_PER_LINE);
    for (idb=0;idb<NUM_LINES;idb++)
    {
      loff=GAP*idb;
      for (idc=0;idc<POINTS_PER_LINE-1;)
      {
        dc->color=colors[ida];
        pp=&p_arr[idc+lgoff];ppp=&p_arr[++idc+lgoff];
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
  F64 time=tS;
  while (TRUE)
  {
    for (iaa=0;iaa<PARTICLE_MAX;iaa++)
    {
      pp=&p_arr[iaa];
      pp->x+=pp->dx;
      pp->y+=pp->dy;

      if (pp->x<=0||pp->x>=WIDTH)
        pp->dx=-pp->dx;
      if (pp->y<=0||pp->y>=HEIGHT)
        pp->dy=-pp->dy;
    }

    if (tS-time>2)
    {
      for (iaa=0;iaa<NUM_GROUPS;iaa++)
      {
        if (colors[iaa]+1==COLORS_NUM) colors[iaa]=BLUE;
        //Take out DKGRAY check, if your DKGRAY is visible
        // in your COLOR scheme.
        else colors[iaa]=colors[iaa]+(1+(colors[iaa]==DKGRAY));
      }
      time=tS;
    }
    
    Sleep(20);
  }
}

U64 Init2() return RandU16%5+1;
U64 Init3() return -1+((RandU16%2==0)*2);
U0 Init()
{
  p_init;
  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];
    
    pp->x=RandU16%WIDTH;
    pp->y=RandU16%HEIGHT;

    pp->dx=Init2*Init3;
    pp->dy=Init2*Init3;
  }
}

ANIMATE_TASK=TRUE;

Fs->win_inhibit|=WIG_DBL_CLICK;

#include "grmain"

p_init;
