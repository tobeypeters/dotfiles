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

/*spiralbox.HC
  Description:
      Draws a spiraling box.
*/
Cd(__DIR__);;

#define PARTICLE_MAX 1

#include "grdefs"

CDC *spi_dc=DCNew(WIDTH,HEIGHT);

U64 col=0;

U0 GenSpiralBox()
{
  pp=&p_arr[0];

  pp->x=WIDTH_CENTER;
  pp->y=HEIGHT_CENTER;

  for (ida=0;ida<256;ida++)
  {
    pp->distance=10+ida;
    pp->dx=pp->x+pp->distance*Cos(pp->angle*M_PI/180);
    pp->dy=pp->y+pp->distance*Sin(pp->angle*M_PI/180);

    spi_dc->color=col;

    if (ida>1)
      GrLine(spi_dc,pp->x,pp->y,pp->dx,pp->dy);

    pp->x=pp->dx;
    pp->y=pp->dy;
    pp->angle+=91;

    if (ida%16==0)
      col=Max(1,(col+1)%16);

    if (ida==240) col=14;
  }
}

U0 DrawIt(CTask *task,CDC *dc)
{
  GrBlot(dc,0,0,spi_dc);
}

U0 AnimateTask(I64) { }

CBGR48 gr_palette_spiral[COLORS_NUM]={
  0x000000000000,0x333300000000,0x666600000000,0x999900000000,
  0xCCCC00000000,0xFFFF00000000,0xFFFF1A1A1A1A,0xFFFF33333333,
  0xFFFF4D4D4D4D,0xFFFF66666666,0xFFFF80808080,0xFFFF99999999,
  0xFFFFB3B3B3B3,0xFFFFCCCCCCCC,0xFFFFC0C0CBCB,0xFFFF8585A1A1
};

Bool init=TRUE;
U0 Init()
{
  if (init)
  {
    p_init;

    GrPaletteSet(gr_palette_spiral);

    GenSpiralBox;

    init=FALSE;
  }
}

Fs->win_inhibit|=WIG_DBL_CLICK;

#include "grmain"

p_init;

GrPaletteSet(gr_palette_std);

DCDel(spi_dc);

Exit;

