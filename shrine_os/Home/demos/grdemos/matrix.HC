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

/*matrix.HC
  Description:
      Horrible rendition, of a matrix effect.
*/
Cd(__DIR__);;

#define PARTICLE_MAX TEXT_COLS
#define PARTICLE_SPEEDS TEXT_COLS

#define OFF1 FONT_HEIGHT
#define OFF2 OFF1*2
#define OFF3 OFF1*3

#include "grdefs"

U8 *chars[4]={"Û","²","±","°"};


U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);
  dc->color=LTGREEN;

  for (ida=0;ida<PARTICLE_MAX;ida++)
  {
    pp=&p_arr[ida];
    GrPrint(dc,pp->x,pp->y-OFF3,chars[3]);
    GrPrint(dc,pp->x,pp->y-OFF2,chars[2]);
    GrPrint(dc,pp->x,pp->y-OFF1,chars[1]);
    GrPrint(dc,pp->x,pp->y,chars[0]);
  }

}

U0 AnimateTask(I64)
{
  while (TRUE) {

    for (itb=0;itb<TEXT_COLS;itb++)
    {
      ppp=&p_arr[itb];

      ppp->y+=ppp->speed;

      if (ppp->y>(TEXT_ROWS*FONT_HEIGHT)) {
        ppp->y=-(RandU16%20)*FONT_HEIGHT;
        ppp->speed=(1+RandU16%3)*FONT_HEIGHT;
      }
    }
    Sleep(100);
  }
}

U0 Init()
{
  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];
    pp->x=ita*FONT_WIDTH;
    pp->y=-(RandU16%TEXT_ROWS)*FONT_HEIGHT;
    pp->speed=(1+RandU16%3)*FONT_HEIGHT;
  }
}

U0 key_down(){ APP_QUIT=TRUE; }
KEY_DOWN=&key_down;

/*U0 ms_l_down(){}
U0 ms_l_up(){}
U0 ms_move(){}
U0 ms_move_ldown(){}
U0 ms_move_rdown(){}
U0 ms_r_down(){}
U0 ms_r_up(){}
U0 key_down(){}

MS_L_DOWN=&ms_l_down;
MS_L_UP=&ms_l_up;
MS_MOVE=&ms_move;
MS_MOVE_LDOWN=&ms_move_ldown;
MS_MOVE_RDOWN=&ms_move_rdown;
MS_R_DOWN=&ms_r_down;
MS_R_UP=&ms_r_up;
KEY_DOWN=&key_down;
*/
ANIMATE_TASK=TRUE;
//MOUSE_TRAP=TRUE;
//MOUSE_NODOWN=FALSE;
Fs->win_inhibit|=WIG_DBL_CLICK;

#include "grmain"

p_init;

Free(chars);

Exit;
