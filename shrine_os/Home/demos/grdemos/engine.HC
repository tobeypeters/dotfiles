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

/*engine.HC
  Description:
      Super generic & simple 3D engine.
*/
Cd(__DIR__);;

#define PARTICLE_MAX 0

#define APP_NAME "3D Engine"
#define APP_VERS "1.0"
#define APP_FMT "%s v%s..."
#define APP_STR MStrPrint(APP_FMT,APP_NAME,APP_VERS)

#include "grdefs"
#include "grutils"
#include "grcontrols"

/*

   ALL THIS IS TEST CODE. IT'S JANKY, MESSY, ETC ....
   STUFF WILL GET MOVED AND MADE CLEANER.

*/

U8 *b1="Message to the templeOS Community";
U64 pw=(10*2)+2, //Button width
    ph=(10*2)+2, //Button height
    bl=180,
    bt=380;

U64 bw=pw+(StrLen(b1)*FONT_WIDTH),
    bh=ph+FONT_WIDTH;

ADocClear;
CD2 p1,p2;
U0 DrawButton(CDC *dc,CCtrl *c)
{
  p1.x=c->left+1;p1.y=c->top+1;
  p2.x=c->right-1;p2.y=c->bottom-1;

  dc->color=CYAN;
  GrRect(dc,c->left,c->top,c->right-c->left,c->bottom-c->top);

  dc->color=c->bg;
//  GrRect(dc,p1.x,p1.y,p2.x-p1.x,p2.y-p1.y);

  if (c->down)
    dc->color=c->light_border;
  else
    dc->color=c->dark_border;

  GrLine(dc,p1.x,p1.y,p2.x-1,p1.y);
  GrLine(dc,p1.x,p1.y+1,p1.x,p2.y-1);

  if (c->down)
    dc->color=c->dark_border;
  else
    dc->color=c->light_border;

  GrLine(dc,p1.x+1,p2.y-1,p2.x-1,p2.y-1);
  GrLine(dc,p2.x-1,p2.y-2,p2.x-1,p1.y+1);

  if (c->down)
    dc->color=c->fg;
  else
    dc->color=c->bg;
  GrPrint(dc,p1.x+pw/2,p1.y+ph/2,"%s",c->label);


  if (c->down)
  {
    dc->color=BLACK;
    GrRect(dc,150,60,340,200);
    dc->color=WHITE;
    GrPrint(dc,150,60,"\n\n\n  Merry Christmas and Happy Holidays ...\n\n


\t\t    *\n
\t\t   ***\n
\t\t  *****\n
\t\t *******\n
\t\t*********\n
\t\t    Û
\t\t----------


");
  }
}

U0 b1LeftClick(CCtrl *c,I64,I64,Bool down)
{
  c->down=down;
}

CCtrl *button=SpawnCtrl(,b1,Fs,&DrawButton,,&b1LeftClick,,,
                        bl,bt,bt+bh,bl+bw);
//button->light_border=WHITE;
//button->dark_border=LTBLUE;

class disp_box
{
  U64 left,
      right,
      width,
      height;
} db;

U0 DrawIt(CTask *task=NULL,CDC *dc)
{
  DCFill(dc,WHITE);

  BoxLineFill(dc);

  ShadowText(dc,APP_STR,FONT_WIDTH,FONT_HEIGHT);

  dc->color=RED;
  GrLine(dc,1,0,db.width-2,0);

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
  db.left=0;
  db.right=0;
  db.width=WIDTH;
  db.height=HEIGHT;

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

QueRem(button);
Free(button);

//p_init;

Exit;