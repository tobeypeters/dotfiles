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

/*grdefs.HC
  Description:
      Graphics related stuff.
*/
/*//I'll incorporate Terry's wherever I can or where I feel I should.
public _extern _D3_ADD CD3 *D3Add(CD3 *sum,CD3 *d1,CD3 *d2); //sum=d1+d2
public _extern _D3_ADD_EQU CD3 *D3AddEqu(CD3 *sum,CD3 *d); //sum+=d
public _extern _D3_COPY CD3 *D3Copy(CD3 *dst,CD3 *src); //dst=src
public _extern _D3_CROSS CD3 *D3Cross(CD3 *prod,CD3 *d1,CD3 *d2); //prod=d1xd2
public _extern _D3_DIST F64 D3Dist(CD3 *d1,CD3 *d2); //Distance
public _extern _D3_DIST_SQR F64 D3DistSqr(CD3 *d1,CD3 *d2); //Distance Squared
public _extern _D3_DIV CD3 *D3Div(CD3 *quot,CD3 *d,F64 s); //quot=d/s
public _extern _D3_DIV_EQU CD3 *D3DivEqu(CD3 *quot,F64 s); //quot/=s
public _extern _D3_DOT F64 D3Dot(CD3 *d1,CD3 *d2); //d1 dot d2
public _extern _D3_EQU CD3 *D3Equ(
	CD3 *dst,F64 x=0,F64 y=0,F64 z=0); //dst=(x,y,z)
public _extern _D3_MUL CD3 *D3Mul(CD3 *prod,F64 s,CD3 *d); //prod=s*d
public _extern _D3_MUL_EQU CD3 *D3MulEqu(CD3 *prod,F64 s); //prod*=s
public _extern _D3_NORM F64 D3Norm(CD3 *d); //Norm
public _extern _D3_NORM_SQR F64 D3NormSqr(CD3 *d); //Norm Squared
public _extern _D3_SUB CD3 *D3Sub(CD3 *diff,CD3 *d1,CD3 *d2); //diff=d1-d2
public _extern _D3_SUB_EQU CD3 *D3SubEqu(CD3 *diff,CD3 *d); //diff-=d
public _extern _D3_UNIT CD3 *D3Unit(CD3 *d); //To unit vect
public _extern _D3_ZERO CD3 *D3Zero(CD3 *dst); //To zero
*/

#define WIDTH GR_WIDTH
#define HEIGHT GR_HEIGHT
#define WIDTH_CENTER WIDTH/2
#define HEIGHT_CENTER HEIGHT/2

class PARTICLE:CD3
{
  Bool active;
  F64 vx,vy,vz, //Velocity x,y,z
      ax,ay,az, //Acceleration x,y,z
      rx,ry,rz, //Rotation x,y,z
      angle,    //Angle
      scale,    //Scale factor
      speed;    //Acceleration all directions

  U64 color;
};

#define PARTICLE_MAX 1000

PARTICLE p_arr[PARTICLE_MAX];

U0 p_init2(PARTICLE *p)
{//Helper function for p_init
  MemSet(p,0,sizeof(PARTICLE));
  p->color=WHITE;

//  p->color=RandU16%COLORS_NUM;
}
U0 p_init(U8 *p,I64 p_cnt)
{
  PARTICLE *pp;

  for (p_cnt--;p_cnt>=0;p_cnt--)
  {
    pp=p+sizeof(PARTICLE)*p_cnt;
    p_init2(pp);
  }
}
U0 p_deinit(U8 *p,U64 p_cnt)
{
  MemSet(p,'\0',sizeof(PARTICLE)*p_cnt);
}

F64 grFloatPack(F64 f1,F64 f2)
{//Packs two floats, into one single float
  F64 res;
  U64 ai,bi;
  MemCpy(&ai,&f1,sizeof(U64));
  MemCpy(&bi,&f2,sizeof(U64));

  "%d %d\n",ai,bi;

  U64 packed=(ai<<32)|bi;

  "packed: %d\n",packed;

  MemCpy(&res,&packed,sizeof(res));

  return res;
}
U0 grFloatUnPack(F64 packed,F64 *f1,F64 *f2)
{//UnPacks two floats, from a single packed float
  U64 raw;

  MemCpy(&raw,&packed,sizeof(raw));

  U64 ai=(raw>>32)&0xFFFFFFFF, //Extract first 32bits
      bi=raw&0xFFFFFFFF;       //Extract last 32bits

  MemCpy(f1,&ai,sizeof(F64));
  MemCpy(f2,&bi,sizeof(F64));
}

F64 x=1.2345,
    y=-2.3456,
    packed=grFloatPack(x,y),
    x_out,y_out;

grFloatUnPack(packed,&x_out,&y_out);

"Original: x=%2.6f,y=%2.6f\n",x,y;
"UnPacked: x=%2.6f,y=%2.6f\n",x_out,y_out;












