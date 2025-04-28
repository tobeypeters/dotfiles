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

/*collision.HC
  Description:
      Messing around with collision detection.  Similiar to how Terry
      did it. But, I may expand upon this.
*/
Cd(__DIR__);;

#define PARTICLE_MAX 0

#include "grdefs"

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  MouseXY(task,&mx,&my);

  dc->color=RED;
  GrRect(dc,200,200,100,100);
  dc->color=LTGREEN;
  GrRect(dc,60,60,20,20);
  dc->color=LTBLUE;
  GrRect(dc,320,60,20,20);

  dc->color=ROP_COLLISION;
  dc->bkcolor=BLACK;
  dc->collision_cnt=0;
  GrCircle(dc,mx,my,30);
  GrRect(dc,mx,my,30,30);
  dc->color=YELLOW;
  GrCircle(dc,mx,my,30);

  GrPrint(dc,FONT_WIDTH,FONT_HEIGHT,
          "Collisions: %d",dc->collision_cnt);

  dc->color=WHITE;
  GrPlot(dc,mx,my);

}

U0 AnimateTask(I64)
{
  while (TRUE) {
    Sleep(20);
  }
}

U0 Init() {}

/*
ANIMATE_TASK=TRUE;
*/

Fs->win_inhibit|=WIG_DBL_CLICK;

#include "grmain"
