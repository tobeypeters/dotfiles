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
      Cheap collision detection.
*/
#define  WIDTH GR_WIDTH
#define HEIGHT GR_HEIGHT

class RECT{
  U64 x,y,w,h;
} rect;

CD3 circle;

U64 sch;

Bool hit=FALSE;

U8 *tf[2]={"FALSE","TRUE"};

U0 collision() {
  //Calculate the distance between the circle's center
  //and the closest point.
  F64 x=circle.x-Max(rect.x,Min(circle.x,rect.x+rect.w)),
      y=circle.y-Max(rect.y,Min(circle.y,rect.y+rect.h));

  //hit=distance less than the circle's radius
  hit=Sqrt(x*x+y*y)<circle.z;
}
U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,WHITE);
//  DCFill(dc,BLACK); //Standard TempleOS

  dc->color=LTBLUE;
  GrRect(dc,rect.x,rect.y,rect.w,rect.h);

  dc->color=LTRED;
  GrCircle(dc,circle.x,circle.y,circle.z);

  GrPrint(dc,FONT_WIDTH*4,FONT_HEIGHT*4,"Collision detected : %s...",tf[hit]);
}

U0 AnimateTask(I64)
{
  while (TRUE) {
    Sleep(20);
  }
}

U0 Init()
{
  rect.x=200;rect.y=150;
  rect.w=200;rect.h=100;
  circle.x=ms.pos.x;
  circle.y=ms.pos.y;
  circle.z=30.0; //Use for radius
  collision;
}

MenuPush(
  "File {"
  "  Abort(,CH_SHIFT_ESC);"
  "  Exit(,CH_ESC);"
  "}"
);

SettingsPush;
AutoComplete;
WinBorder; WinMax;
DocCursor; DocClear;

Init;

Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",,Fs);
Fs->draw_it=&DrawIt;

I64 arg1,arg2,sc;

Bool run=TRUE;

try {
  while (run) {
    sc=GetMsg(&arg1,&arg2,1<<MSG_KEY_DOWN+1<<MSG_MS_L_DOWN+
             1<<MSG_MS_L_UP+1<<MSG_MS_R_DOWN+1<<MSG_MS_R_UP+1<<MSG_MS_MOVE);
    switch (sc) {
      case MSG_MS_MOVE:
        circle.x=ms.pos.x;
        circle.y=ms.pos.y;

        collision;

        break;
      case MSG_KEY_DOWN:
        if (arg1==CH_SHIFT_ESC||arg1==CH_ESC)
          run=FALSE;
    }
    Refresh;
  }
} catch
  PutExcept;


SettingsPop;
MenuPop;
