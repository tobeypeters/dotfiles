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

/*utils.HC
  Description:
      Miscellaneous functions.
*/

U0 set_windowinfo(U8 *name=NULL,U8 *title=NULL)
{//Allows you to set Fs values:
 //Fs->task_name
 //Fs->task_title
  if (name) StrCpy(Fs->task_name,name);
  if (title) StrCpy(Fs->task_title,title);
}

//NOTE: MIGHT MOVE SOME OF THESE INTO THE OS FILES.


Bool I64_IN(I64 inval,...)
{//Check to see if an I64 is in a given argv list.
  U64 i = 0;

  for (;i<argc;i++) {
    if (inval == argv[i]) {
      return TRUE;
    }
  }

  return FALSE;
}

U8 tern(Bool condition, U64 *first, U64 *second)
{//Ternary operator like function.
  if (condition) return first;

  return second;
}



U0 shell_execute(U8 *cmd)
{//Execute a templeOS shell command.
  "\n"; ExePutS(cmd); "\n";
}

U0 viewer(U8 *cmd)
{//Execute a specified command and examine the results
 //in "view" mode.
  DocClear; DocTop;
  ExePutS(cmd);
  "$$BK,1$$Press ESC to exit ...$$BK,0$$";
  DocTop;View; DocBottom;
  PutChars(CH_CTRLY);
}

I64 map_value(I64 x,I64 in_min,I64 in_max,I64 out_min,I64 out_max)
{//Map one range to another range.
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}


