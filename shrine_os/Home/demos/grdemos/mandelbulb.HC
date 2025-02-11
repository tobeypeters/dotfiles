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
Cd(__DIR__);;

#define DIM 65

#define PARTICLE_MAX DIM*DIM*DIM

#include "grdefs"

Bool pgr=FALSE,init;

U8 *pgrc[2]={"-","|"};

U64 pc;

U0 DrawIt(CTask *task,CDC *dc)
{
//  DCFill(dc,BLACK);
  dc->color=LTRED;

  if (init) {
    GrPrint(dc,FONT_WIDTH,FONT_HEIGHT,"[%s] Generating points ...",pgrc[pgr]);
    pgr=!pgr;
  }
  else
    GrPrint(dc,FONT_WIDTH,FONT_HEIGHT*2,"Hold left mouse button down and drag the cursor around,\nto rotate the mandelbulb.");

  for(ita=0;ita<pc;ita++)
  {
    p_DUP(pp,&p_arr[ita]);

    //Apply rotation
    rot_plot(pp);

    dc->color=MapI64(ita,0,pc-1,0,15);
    GrPlot(dc,(pp->x*WIDTH/4)+WIDTH/2,(pp->y*HEIGHT/4)+HEIGHT/2);
  }

}
U0 AnimateTask(I64){}

U0 Init2(U64 it)
{
  F64 x,y,z,hp,ht,nx,ny,nz;

  U64 max_iter=20,
             n=10,
             iter;

  PARTICLE zeta;

  Bool edge;

  init=TRUE;

  Yield;

  for (itb=0;itb<DIM;itb++) {
    edge=FALSE; 
    for (itc=0;itc<DIM;itc++)
    {
      x=ToF64(it.u8[0])/(DIM-1)*2-1,
      y=ToF64(itb)/(DIM-1)*2-1,
      z=ToF64(itc)/(DIM-1)*2-1;

      p_init2(&zeta);

      iter=0;

      while (TRUE) {
        spherize(&zeta);

        ht=zeta.pt*n;hp=zeta.pp*n;
        nx=Pow(zeta.pr,n)*Sin(ht)*Cos(hp),
        ny=Pow(zeta.pr,n)*Sin(ht)*Sin(hp),
        nz=Pow(zeta.pr,n)*Cos(ht);

        zeta.x=nx+x;zeta.y=ny+y;zeta.z=nz+z;

        iter++;

        if (zeta.pr>2) {
          if (edge)
            edge=FALSE;
          break;
        }

        if (iter>max_iter) {
          if (!edge) {
            edge=TRUE;

            p_arr[pc].x=x;
            p_arr[pc].y=y;
            p_arr[pc].z=z;
            pc++;
          }
          break;
        }
      }
    }//itc
  }//itb

  init=FALSE;
}

U0 Init()
{
  U64 pass,m,bi;

  rotation_x=-0.31378758,
  rotation_y=-0.29036515;

  pc=m=0;

  pass.u8[1]=DIM/mp_cnt;
  pass.u8[2]=DIM-pass.u8[1]*mp_cnt;

  for (ita=m=0;ita<DIM;ita+=pass.u8[1]) {
    lock;

    pass.u8[0]=ita;

    bi=DIM;

    while(m<mp_cnt)
    {
      pass.u8[7]=m;
      JobQue(&Init2,pass,m,0);
      bi-=pass.u8[1];
      m++;
    }

    m=0;

    if (bi>0) {
      pass.u8[1]=pass.u8[2];
      JobQue(&Init2,pass,mp_cnt-1,0);
    }
  }
}

U0 MS_L_DOWN(){}
U0 MS_L_UP(){}
U0 MS_MOVE(){}
U0 MS_MOVE_LDOWN()
{
  rotation_x+=(cur_mouse_y-prev_mouse_y)*0.001;
  rotation_y+=(cur_mouse_x-prev_mouse_x)*0.001;
}
U0 MS_MOVE_RDOWN(){}
U0 MS_R_DOWN(){}
U0 MS_R_UP(){}
U0 KEY_DOWN(){}

#define ANIMATE_TASK FALSE

#define MOUSE_TRAP TRUE

//Update mouse postion values,
//even when mouse button not pressed.
#define MOUSE_NODOWN FALSE

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);
