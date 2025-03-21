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

#define PARTICLE_MAX 4

#include "grdefs"

//PARTICLE p_arr2D[NUM_LINES][POINTS_PER_LINE];

#define LINE_SPACING 5

U64 loff=3;
U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);
  dc->color=LTGREEN;


  for (ita=0;ita<PARTICLE_MAX-1;)
  {
    pp=&p_arr[ita];ppp=&p_arr[++ita];
    GrLine(dc,pp->x,pp->y,ppp->x,ppp->y);
    GrLine(dc,pp->x+loff,pp->y+loff,ppp->x+loff,ppp->y+loff);
//    GrPrint(dc,pp->x,pp->y,"%d",ita-1);
//    GrPrint(dc,ppp->x,ppp->y,"%d",ita);
  }

  GrLine(dc,p_arr[POINTS_PER_LINE-1].x,
    p_arr[POINTS_PER_LINE-1].y,
    p_arr[0].x,p_arr[0].y);
  GrLine(dc,p_arr[POINTS_PER_LINE-1].x+loff,
    p_arr[POINTS_PER_LINE-1].y+loff,
    p_arr[0].x+loff,p_arr[0].y+loff);

/*  for (ita=0;ita<NUM_LINES;ita++)
  {
    for (itb=0;itb<POINTS_PER_LINE-1;itb++)
    {
      loff=ita*LINE_SPACING;

      GrLine(dc,p_arr2D[ita][itb].x+loff,
                p_arr2D[ita][itb].y+loff,
                p_arr2D[ita][itb+1].x+loff,
                p_arr2D[ita][itb+1].y+loff);
    }

    GrLine(dc,p_arr2D[ita][POINTS_PER_LINE-1].x+loff,
    p_arr2D[ita][POINTS_PER_LINE-1].y+loff,
    p_arr2D[ita][0].x+loff,p_arr2D[ita][0].y+loff);
  }
*/
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
    }

/*    for (ita=0;ita<NUM_LINES;ita++)
    {
      for (itb=0;itb<NUM_LINES;itb++)
      {
        pp=&p_arr2D[ita][itb];
        pp->x+=pp->dx;
        pp->y+=pp->dy;

        if (pp->x<=0||pp->x>=WIDTH)
          pp->dx=-pp->dx;
        if (pp->y<=0||pp->y>=HEIGHT)
          pp->dy=-pp->dy;
      }
    }
*/
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

/*  for (ita=0;ita<NUM_LINES;ita++)
  {
    for (itb=0;itb<POINTS_PER_LINE;itb++)
    {
      pp=&p_arr2D[ita][itb];

      pp->x=RandU16%WIDTH;
      pp->y=RandU16%HEIGHT;

      pp->dx=Init3*Init2;
      pp->dy=Init3*Init2; 
    }
  }
*/
}

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

MOUSE_TRAP=FALSE;
MOUSE_NODOWN=FALSE;
*/

ANIMATE_TASK=TRUE;

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);
