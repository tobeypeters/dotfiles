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

/*mandelbulb.HC
  Description:
      Generates a mandelbulb.
  Resources:
      https://en.wikipedia.org/wiki/Mandelbulb
*/
#define  WIDTH GR_WIDTH
#define HEIGHT GR_HEIGHT

#define DIM 128

CD3 mandelbulb[DIM*DIM*DIM];

U64 prev_mouse_x=0,
    prev_mouse_y=0,
    sch,ip=0;

F64 rotation_x=-0.31378758,
    rotation_y=-0.29036515;

U64 pc=0;

Bool init=TRUE,run=TRUE,mouse_down=FALSE;

I64 map(I64 x,I64 in_min,I64 in_max,I64 out_min,I64 out_max)
  return (x- in_min)*(out_max-out_min)/(in_max-in_min)+out_min;

U0 spherize(F64 zx,F64 zy,F64 zz,F64 *r,F64 *theta,F64 *phi) {
  *r=Sqrt(zx*zx+zy*zy+zz*zz);
  *theta=ATan2(Sqrt(zx*zx+zy*zy),zz);
  *phi=ATan2(zy,zx);
}

U0 rot_plot(CD3 *rp,F64 *rx,F64 *ry,F64 *rz) {
  F64 cos_x=Cos(rotation_x),
       cos_y=Cos(rotation_y),
       sin_x=Sin(rotation_x),
       sin_y=Sin(rotation_y),
          y1=cos_x*rp->y-sin_x*rp->z,
          z1=sin_x*rp->y+cos_x*rp->z,
          x2=cos_y*rp->x+sin_y*z1,
          z2=-sin_y*rp->x+cos_y*z1;

  *rx=x2;*ry=y1;*rz=z2;
}

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(BLACK);

  dc->color=LTRED;

  if (init) {
   GrPrint(dc,FONT_WIDTH,FONT_HEIGHT,"Generating points: %d%%",ip);
   return;
  }
  else
   GrPrint(dc,FONT_WIDTH,FONT_HEIGHT,"Generating points: Complete");

  GrPrint(dc,FONT_WIDTH,FONT_HEIGHT*2,"Hold left mouse button down and drag the cursor around to rotate the mandelbulb.");

  U64 i;

  F64 px,py,pz;

  for(i=0;i<pc;i++)
  {
    dc->color=map(i,0,ToI64(pc-1),0,15);
    rot_plot(&mandelbulb[i],&px,&py,&pz);
    GrPlot(dc,(px*WIDTH/4)+WIDTH/2,(py*HEIGHT/4)+HEIGHT/2);
  }
}

U0 Init()
{
  U64 i,j,k,n=8,
      maxiterations=20;

  F64 zetax,zetay,zetaz;
  F64 cr,ctheta,cphi;

  for (i=0;i<DIM;i++) {
    ip=(i*100)/DIM;

    Refresh;

    for (j=0;j<DIM;j++) {
      Bool edge=FALSE;
      for (k=0;k<DIM;k++) {
        F64 x=ToF64(i)/(DIM-1)*2-1,
            y=ToF64(j)/(DIM-1)*2-1,
            z=ToF64(k)/(DIM-1)*2-1;

        zetax=zetay=zetaz=0;

        U64 iteration=0;

        while (TRUE) {
          spherize(zetax,zetay,zetaz,&cr,&ctheta,&cphi);
          F64 newx=Pow(cr,n)*Sin(ctheta*n)*Cos(cphi*n),
              newy=Pow(cr,n)*Sin(ctheta*n)*Sin(cphi*n),
              newz=Pow(cr,n)*Cos(ctheta*n);

          zetax=newx+x;
          zetay=newy+y;
          zetaz=newz+z;

          iteration++;

          if (cr>2) {
            if (edge) {
              edge=FALSE;
            }
            break;
          }


          if (iteration>maxiterations) {
            if (!edge) {
              edge=TRUE;

              mandelbulb[pc].x=x;
              mandelbulb[pc].y=y;
              mandelbulb[pc].z=z;
              pc++;
            }
            break;
          }
        }
      }
    }
  }

  init=FALSE;
}

I64 arg1,arg2,sc,dx,dy;

MenuPush(
  "File {"
  "  Abort(,CH_SHIFT_ESC);"
  "  Exit(,CH_ESC);"
  "}"
  "Play {"
  "}"
);

SettingsPush;
AutoComplete;
WinBorder; WinMax;
DocCursor; DocClear;

Fs->draw_it=&DrawIt;

Init;

try {
  while (run) {
    sc=GetMsg(&arg1,&arg2,1<<MSG_KEY_DOWN+1<<MSG_MS_L_DOWN+
             1<<MSG_MS_L_UP+1<<MSG_MS_R_DOWN+1<<MSG_MS_R_UP+1<<MSG_MS_MOVE);
    switch (sc) {
      case MSG_MS_L_DOWN:
        mouse_down=TRUE;

        prev_mouse_x=ms.pos.x;
        prev_mouse_y=ms.pos.y;
        break;
      case MSG_MS_MOVE:
        if (mouse_down)
        {
          dx=ms.pos.x-prev_mouse_x;
          dy=ms.pos.y-prev_mouse_y;

          rotation_x+=dy*0.01;
          rotation_y+=dx*0.01;

          prev_mouse_x=ms.pos.x;
          prev_mouse_y=ms.pos.y;
        }

        break;
      case MSG_MS_L_UP:
        mouse_down=FALSE;
        break;
      case MSG_MS_R_DOWN:
      case MSG_MS_R_UP:
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
