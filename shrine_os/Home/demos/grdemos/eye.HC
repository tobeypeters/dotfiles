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
      Works best if it's drawn,in the center of the screen;
*/
Cd(__DIR__);;

#define PARTICLE_MAX 0

#include "grdefs"

//#define EYE_SIZE 64
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
//  GrPrint(dc,WIDTH_CENTER,HEIGHT_CENTER,"%s","ÿ");
  GrPrint(dc,0,0,"%s","ÿ");
}

U64 bitdex(U64 x,U64 y) return y*8+x;
U0 AnimateTask(I64)
{
  U64 px,py;

  F64 angle=0;

  while (TRUE)
  {
    text.font[255]=base_eye[0](U64);

    angle=ATan2(ms.pos.y/(GR_HEIGHT/8)-4,
                ms.pos.x/(GR_WIDTH/8)-4);

    px=4+Cos(angle)*2; py=4+Sin(angle)*2;    

    Btr(&text.font[255],bitdex(px,py));
    Btr(&text.font[255],bitdex(px+1,py));
    Btr(&text.font[255],bitdex(px,py+1));
    Btr(&text.font[255],bitdex(px+1,py+1));

    Sleep(20);
  }
}

U0 Init(){}

ANIMATE_TASK=TRUE;

Fs->win_inhibit|=WIG_DBL_CLICK;

#include "grmain"

