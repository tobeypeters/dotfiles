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

/*grglobs.HC
  Description:
      Global/default variables and functions.
*/
F64 rotation_x,
    rotation_y;

I64 cur_mouse_x,
    cur_mouse_y,
    prev_mouse_x,
    prev_mouse_y,
    ida,idb,idc,
    ita,itb,itc,ch,sc;

cur_mouse_x=cur_mouse_y=
prev_mouse_x=prev_mouse_y=
rotation_x=rotation_y=
ita=itb=itc=0;

Bool ANIMATE_TASK,MOUSE_TRAP,
     MOUSE_NODOWN; //Update mouse postion values
                   //even when mouse button not pressed.

ANIMATE_TASK=MOUSE_TRAP=MOUSE_NODOWN=FALSE;

U0 ms_l_down(){}
U0 ms_l_up(){}
U0 ms_move(){}
U0 ms_move_ldown(){}
U0 ms_move_rdown(){}
U0 ms_r_down(){}
U0 ms_r_up(){}
U0 key_down(){}

U0 (*MS_L_DOWN)()=&ms_l_down;
U0 (*MS_L_UP)()=&ms_l_up;
U0 (*MS_MOVE)()=&ms_move;
U0 (*MS_MOVE_LDOWN)()=&ms_move_ldown;
U0 (*MS_MOVE_RDOWN)()=&ms_move_rdown;
U0 (*MS_R_DOWN)()=&ms_r_down;
U0 (*MS_R_UP)()=&ms_r_up;
U0 (*KEY_DOWN)()=&key_down;
