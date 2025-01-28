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

/*module.HC
  Description:
      Graphics module template.
*/
Cd(__DIR__);;

#define PARTICLE_MAX 1000

#include "grdefs"

U64 i;

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);
  for (i=0;i<PARTICLE_MAX;i++)
  {
  }
}

U0 AnimateTask(I64)
{
  while (TRUE) {
    Sleep(20);
  }
}

U0 Init()
{
  p_deinit(&p_arr,PARTICLE_MAX);
}

U0 MS_L_DOWN()
{
}
U0 MS_L_UP()
{
}
U0 MS_MOVE()
{
}
U0 MS_R_DOWN()
{
}
U0 MS_R_UP()
{
}
U0 KEY_DOWN()
{
}

#define MOUSE_TRAP FALSE

#include "grmain"