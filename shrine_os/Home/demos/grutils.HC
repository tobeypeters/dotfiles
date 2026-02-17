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

/*grutils.HC
  Description:
     Misc generic graphic routines.
*/

#define HORZ_LINES 0
#define VERT_LINES 1

U0 BoxLineFill(CDC *dc,U64 direction=HORZ_LINES,U64 colora=LTRED,U64 colorb=RED)
{
  switch (direction)
  {
    case HORZ_LINES:
      break;
    case VERT_LINES:
      break;
  }

  for (ida=0;ida<WIDTH;ida++)
  {
    if (ida%2)
      dc->color=colora;
    else
      dc->color=colorb;

    GrLine(dc,ida,0,ida,HEIGHT);
  }
}

U0 ShadowText(CDC *dc,U8 *txt,U64 x,U64 y,U64 off=2,U64 colora=WHITE,U64 colorb=BLACK)
{//Draw text with a shadow
  dc->color=colorb;
  GrPrint(dc,x+off,y+off,txt);
  dc->color=colora;
  GrPrint(dc,x,y,txt);
}
