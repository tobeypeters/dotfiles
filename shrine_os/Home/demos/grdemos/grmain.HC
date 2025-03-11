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

/*grmain.HC
  Description:
      Main loop, for graphic demos.
*/
//Cd(__DIR__);;
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

Init;

if (ANIMATE_TASK)
  Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",,Fs);
Fs->draw_it=&DrawIt;

if (MOUSE_TRAP)
{
  I64 arg1,arg2,mx,my;;

  Bool mouse_ldown=FALSE,
       mouse_rdown=FALSE,
              run=TRUE;;
}

try {
if (MOUSE_TRAP)
{
  while (run) {
    sc=GetMsg(&arg1,&arg2,1<<MSG_KEY_DOWN+1<<MSG_MS_L_DOWN+
             1<<MSG_MS_L_UP+1<<MSG_MS_R_DOWN+1<<MSG_MS_R_UP+1<<MSG_MS_MOVE);
    cur_mouse_x=ms.pos.x;cur_mouse_y=ms.pos.y;

    switch (sc) {
      case MSG_MS_L_DOWN:
        mouse_ldown=TRUE;
	MS_L_DOWN;

        break;
      case MSG_MS_MOVE:
        if (MOUSE_NODOWN||mouse_ldown||mouse_rdown)
        {
          if (MOUSE_NODOWN) MS_MOVE;
        }

        if(mouse_ldown) MS_MOVE_LDOWN;
        if(mouse_rdown) MS_MOVE_RDOWN;

        prev_mouse_x=mx;
        prev_mouse_y=my;

        break;
      case MSG_MS_L_UP:
        mouse_ldown=FALSE;
        MS_L_UP;

        break;
      case MSG_MS_R_DOWN:
        mouse_rdown=TRUE;
        MS_R_DOWN;

        break;
      case MSG_MS_R_UP:
        mouse_rdown=FALSE;
        MS_R_UP;

        break;
      case MSG_KEY_DOWN:
        KEY_DOWN;
        if (arg1==CH_SHIFT_ESC||arg1==CH_ESC)
          run=FALSE;
    }
//    Refresh;
  }
}
else
{
  do
    switch (ch=GetKey(&sc)) {
      case '\n'://Perhaps move this into modules' KEY_DOWN
        Init;
      	break;
      default:
        KEY_DOWN;
        break;
    }
  while (ch!=CH_ESC && ch!=CH_SHIFT_ESC);
}

}
catch
  PutExcept;

SettingsPop;
MenuPop;
