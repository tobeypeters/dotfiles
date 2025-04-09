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

/*fire.HC
  Description:
      Generates a fire effect.
*/
Cd(__DIR__);;

I64 PIXEL_SIZE=4;

#define FIRE_WIDTH (WIDTH/PIXEL_SIZE)
#define FIRE_HEIGHT (HEIGHT/PIXEL_SIZE)

#define PARTICLE_MAX FIRE_WIDTH*FIRE_HEIGHT
#define COLOR_CNT 5

#include "grdefs"

U64 COLORS[COLOR_CNT]={BLACK,RED,LTRED,YELLOW,WHITE};
U64 Color_IDX(U64 color)
{
  for (itc=0;itc<COLOR_CNT;itc++)
    if (COLORS[itc]==color) return itc;
}

I64 ft,ft2;

U64 Init2(U64 x,U64 y) return y*FIRE_WIDTH+x;
U0 DrawIt(CTask *task,CDC *dc)
{
//  DCFill(dc,BLACK);

//  p_plot(dc,&p_arr,PARTICLE_MAX);

  for (ida=0;ida<FIRE_HEIGHT;ida++)
  {
    for (idb=0;idb<FIRE_WIDTH;idb++)
    {
      pp=&p_arr[Init2(idb,ida)];

      dc->color=pp->color;
      GrRect(dc,pp->x,pp->y,PIXEL_SIZE,PIXEL_SIZE);
      GrRegPoly(dc,pp->x,pp->y,ft,ft2,PIXEL_SIZE);
      GrFloodFill(dc,pp->x,pp->y);

    }
  }

  dc->color=LTBLUE;
  GrPrint(dc,FONT_WIDTH,FONT_HEIGHT,"FLAME STYLE: %d.%d",ft,ft2);
}

U64 color,dx,nx,rnd;
U0 AnimateTask(I64)
{
  while (TRUE) {
    for (ita=1;ita<FIRE_HEIGHT;ita++)
    {
      for (itb=0;itb<FIRE_WIDTH;itb++)
      {
        ppp=&p_arr[Init2(itb,ita)];

        if ((color=Color_IDX(ppp->color))>0)
        {
          rnd=RandU16&3;
          nx=itb-rnd+1;
          if (nx<0) nx=0;
          if (nx>=FIRE_WIDTH) nx=FIRE_WIDTH-1;

          color=color-(rnd&1);

          p_arr[Init2(nx,ita-1)].color=COLORS[color];

        } else p_arr[Init2(itb,ita-1)].color=COLORS[0];
      }
    }

    Sleep(20);
  }
}

U0 Init()
{
  for (ita=0;ita<FIRE_HEIGHT;ita++)
  {
    for (itb=0;itb< FIRE_WIDTH;itb++)
    {
      pp=&p_arr[Init2(itb,ita)];
      pp->color=COLORS[4];
      pp->x=itb*PIXEL_SIZE;
      pp->y=ita*PIXEL_SIZE;
    }
  }

  ft=1,ft2=5;
}
U0 key_down()
{
  switch (sc.u8[0]) {
    case 72:
    case 80:
      ft+=(sc.u8[0]==72)-(sc.u8[0]==80);
      ft=Max(0,ft)%10;
      break;
    case 75:
    case 77:
      ft2+=(sc.u8[0]==77)-(sc.u8[0]==75);
      ft2=Max(0,ft2)%10;
  }
}
KEY_DOWN=&key_down;

ANIMATE_TASK=TRUE;

Fs->win_inhibit|=WIG_DBL_CLICK;

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);
