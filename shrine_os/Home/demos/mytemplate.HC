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

/*mytemplate.HC
  Description:
      Empty project template.
*/
//Cd(__DIR__);;

//CDC *cdc=DCNew(GR_WIDTH,GR_HEIGHT);

#define  WIDTH GR_WIDTH
#define HEIGHT GR_HEIGHT

U64 sch;

//CDC *cdc=DCNew(GR_WIDTH,GR_HEIGHT);


U0 DrawIt(CTask *task,CDC *dc)
{
  /*cdc=dc;

  if (Bt(kbd.down_bitmap,sch)) "test";

  cdc->color=ROP_EQU;
  dc->flags|=DCF_NO_TRANSPARENTS;
  GrBlot(cdc,-task->pix_left-task->scroll_x,
	-task->pix_top-task->scroll_y,dc);
  dc->flags&=~DCF_NO_TRANSPARENTS;*/
}

U0 AnimateTask(I64)
{
  while (TRUE) {
    Sleep(20);
  }
}

U0 Init()
{
}

I64 ch,sc;
MenuPush(
  "File {"
  "  Abort(,CH_SHIFT_ESC);"
  "  Exit(,CH_ESC);"
  "}"
  "Play {"
  "  Restart(,'\n');"
  "}"
);

SettingsPush;
AutoComplete;
WinBorder; WinMax;
DocCursor; DocClear;

//Fs->win_inhibit=WIG_TASK_DFT-WIF_SELF_FOCUS-WIF_SELF_BORDER;

Init;

sch=Char2ScanCode('h');

//Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",mp_cnt-1);
Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",,Fs);
Fs->draw_it=&DrawIt;

try {
  do
    switch (ch=GetKey(&sc)) {
      case '\n':
        Init;
      break;
    }
  while (ch!=CH_ESC && ch!=CH_SHIFT_ESC);
}
catch
  PutExcept;

//cdc=NULL;

//DCDel(cdc);

SettingsPop;
MenuPop;
