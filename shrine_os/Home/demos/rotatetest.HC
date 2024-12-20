/*
  The MIT License(MIT)
  Copyright(c), Tobey Peters, https://github.com/tobeypeters
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
  and associated documentation files (the "Software"), to deal in the Software without restriction,
  including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
  subject to the following conditions:
  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*rotatetest.HC
  Description:
      Displays a rotating square.
*/

U64 cx=GR_WIDTH/2,
    cy=GR_HEIGHT/2,i;

CD2 p1,p2,center;

CD2 corners[4];

F64 angle=1.0; // Initial angle

//Function to rotate a point using matrix multiplication
U0 rot_matrix(U64 idx) {
  F64 radians=angle*(ã/180.0),
    cos_é=Cos(radians),
    sin_é=Sin(radians),
            x=corners[idx].x-center.x,
            y=corners[idx].y-center.y,
        x_new=x*cos_é-y*sin_é,
        y_new=x*sin_é+y*cos_é;

  corners[idx].x=x_new+center.x;
  corners[idx].y=y_new+center.y;
}
U0 DrawIt(CTask *task,CDC *dc)
{
  dc->color=RED;
  GrLine(dc,corners[0].x,corners[0].y,corners[1].x,corners[1].y);
  GrLine(dc,corners[3].x,corners[3].y,corners[2].x,corners[2].y);
  GrLine(dc,corners[3].x,corners[3].y,corners[0].x,corners[0].y);
  GrLine(dc,corners[2].x,corners[2].y,corners[1].x,corners[1].y);
}
U0 AnimateTask(I64)
{
  while (TRUE) {
    for(i=0;i<4;i++) {
      rot_matrix(i); // Rotate 1 degree per frame
    }
    Sleep(20);
  }

}
U0 Init()
{
  // Define initial square points
  p1.x=cx-50;p1.y=cy-50;
  p2.x=cx+50;p2.y=cy+50;

  // Center of the square
  center.x=(p1.x+p2.x)/2;
  center.y=(p1.y+p2.y)/2;

  //Diagonal length from p1 to p2 divided by two.
  //This ONLY works for squares.
  F64 side=(Sqrt(Pow(p2.x-p1.x,2)+Pow(p2.y-p1.y,2))/Sqrt(2))/2;

  //Initial square corners
  //Bottom-left,Bottom-right,Top-right,Top-left
  corners[0].x=corners[3].x=center.x-side;
  corners[1].x=corners[2].x=center.x+side;
  corners[0].y=corners[1].y=center.y-side;
  corners[2].y=corners[3].y=center.y+side;
}

MenuPush(
  "File {"
  "  Abort(,CH_SHIFT_ESC);"
  "  Exit(,CH_ESC);"
  "}"
);

I64 ch,sc;

SettingsPush;
AutoComplete;
WinBorder; WinMax;
DocCursor; DocClear;

Init;

Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",,Fs);
Fs->draw_it=&DrawIt;

try {
  do
    ch=GetKey(&sc);
  while (ch!=CH_ESC && ch!=CH_SHIFT_ESC);
}
catch
  PutExcept;

SettingsPop;
MenuPop;
