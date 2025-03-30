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

/*eye.HC
  Description:
      Eye which tracks the mouse pointer.
*/
Cd(__DIR__);;

#define PARTICLE_MAX 0

#include "grdefs"

#define EYE_SIZE 64
#define PUPIL_SIZE 2

U8 base_eye[8] = {
    0b00111100,
    0b01111110,
    0b11111111,
    0b11111111,
    0b11111111,
    0b11111111,
    0b01111110,
    0b00111100
};

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);
  dc->color=LTGREEN;
  GrPrint(dc,10,10,"%s","ÿ");
}

I64 cx=4,cy=4,dx,dy,px,py,pxp,pyp;

Bool once=TRUE;ADocClear;
U0 AnimateTask(I64)
{
  while (TRUE)
  {
    text.font[255]=base_eye[0](U64);

    dx=(ms.pos.x)/(WIDTH/8)-cx;
    dy=(ms.pos.y)/(HEIGHT/8)-cy;

    if (dx<-2) dx=-2;
    if (dx>2) dx=2;
    if (dy<-2) dy=-2;

    if (dy>1) dy=1; // Restrict top movement to base_eye[4]

    px=cx+dx;py=cy+dy;

    if (px>5) px=5;

    for (ita=-PUPIL_SIZE/2;ita<=PUPIL_SIZE/2;ita++)
    {
      for (itb=-PUPIL_SIZE/2;itb<=PUPIL_SIZE/2;itb++)
      {
        pxp=px+itb; pyp=py+ita;
        if (pxp>=0&&pxp<8&&pyp>=0&&pyp<8)
          Btr(&text.font[255],(pyp*8)+pxp);
        else Bts(&text.font[255],(pyp*8)+pxp);
      }
    }

    Sleep(20);
  }
}

U0 Init(){}

ANIMATE_TASK=TRUE;

#include "grmain"

