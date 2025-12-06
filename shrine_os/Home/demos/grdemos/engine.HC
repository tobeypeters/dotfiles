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

/*enginee.HC
  Description:
      Super generic & simple 3D engine.
*/
Cd(__DIR__);;

#define PARTICLE_MAX 1000

#define APP_NAME "Engine"
#define APP_VERS "1.0"

#include "grdefs"

U0 DrawIt(CTask *task=NULL,CDC *dc)
{
  DCFill(dc,WHITE);


  for (ida=0;ida<WIDTH;ida++)
  {
    if (ida%2)
      dc->color=LTRED;
    else
      dc->color=RED;

    GrLine(dc,ida,0,ida,HEIGHT);
  }


  dc->color=BLACK;
  GrPrint(dc,(FONT_WIDTH+2),FONT_HEIGHT*2-(FONT_HEIGHT*.75),"%s %s...",APP_NAME,APP_VERS);
  dc->color=WHITE;
  GrPrint(dc,(FONT_WIDTH),FONT_HEIGHT,"%s %s...",APP_NAME,APP_VERS);

  //MouseXY(task,&mx,&my);
  //p_plot(dc);
  /*for (ida=0;ida<PARTICLE_MAX;ida++)
  {
    pp=&p_arr[ida];
  }*/
}

U0 AnimateTask(I64)
{
  while (TRUE) {
    Sleep(20);
  }
}

U0 Init()
{
  //p_deinit(&p_arr,PARTICLE_MAX);
  //p_init;
  /*for (ita=0;ita<PARTICLE_MAX;ita++)
  {
  }*/
}

U0 ms_l_down(){}
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

ANIMATE_TASK=FALSE;
MOUSE_TRAP=FALSE;
MOUSE_NODOWN=FALSE;
Fs->win_inhibit|=WIG_DBL_CLICK;


#include "grmain"

p_init;

Exit;