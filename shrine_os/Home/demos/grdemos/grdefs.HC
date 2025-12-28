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
/*
//I'll incorporate Terry's wherever I can or atleast leave
//commented out code, which shows how to use his to do whatever I'm doing.
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
//#define PARTICLE_MAX 10
//U64 itp;

#include "grglobs"

//You really need to do WinBorder;WinMax; first and
//Get Fs->pix_width & Fs->pix_height. That'll give you 640 x 472
#define WIDTH ToF64(GR_WIDTH)
#define HEIGHT ToF64(GR_HEIGHT-9)
#define WIDTH_CENTER ToF64(WIDTH/2)
#define HEIGHT_CENTER ToF64(HEIGHT/2)

/*
I've been using the TempleOS PI symbol <alt>+<1>,
But, that chr doesn't "exist" outside of TempleOS.
Editing outside TempleOS corrupts your file and viewing on GitHub,
shows "garbage" wherever those characted are. :<
*/
#define M_PI 3.14159265

class PARTICLE_BASE:CD3
{
  Bool active;
  U64 color;
};
class PARTICLE:PARTICLE_BASE
{
  F64 vx,vy,vz, //Velocity x,y,z
      ax,ay,az, //Acceleration x,y,z
      rx,ry,rz, //Rotation x,y,z
      px,py,pz, //Previous x,y,z
      pr,pt,pp, //Polar coordiantes - r,theta,phi
      dx,dy,dz, //Distance x,y,z
      distance, //Distance
      angle,    //Angle
      scale,    //Scale factor
      speed;    //Acceleration all directions
};

PARTICLE p_arr[PARTICLE_MAX];

PARTICLE *pp=NULL,*ppp=NULL; //External use pointer

U0 p_DUP(U8 *dst,U8 *src)
{//Duplicat a PARTICLE
  MemCpy(dst,src,sizeof(PARTICLE));
}

U0 p_init2(PARTICLE *p)
{//(Re)Init a PARTICLE element
  MemSet(p,0,sizeof(PARTICLE));
  p->color=WHITE;
}
U0 p_init(U8 *p=p_arr,U64 p_cnt=PARTICLE_MAX)
{//Re(Init) a PARTICLE array
  MemSet(p,'\0',sizeof(PARTICLE)*p_cnt);
}
U0 p_init_rep(U8 *p=p_arr,PARTICLE *el,I64 p_cnt=PARTICLE_MAX)
{//(Re)Init a PARTICLE array,populating it with a given PARTICLE
  for (p_cnt--;p_cnt>=0;p_cnt--)
  {
    pp=p+sizeof(PARTICLE)*p_cnt;
    p_DUP(pp,el);
  }
}

/*PARTICLE tp;
tp.angle=37;tp.speed=68;

p_init_rep(,&tp);
"speed: %2.8f\n",p_arr[0].speed;
"angle: %2.8f\n",p_arr[0].angle;
"speed: %2.8f\n",p_arr[4].speed;
"angle: %2.8f\n\n",p_arr[7].angle;
*/
U0 p_plot(CDC *dc,U8 *p=p_arr,U64 p_cnt=PARTICLE_MAX)
{
  for(itp=0;itp<p_cnt;itp++)
  {
    pp=p+sizeof(PARTICLE)*itp;
    dc->color=pp->color; //If you used p_init... WHITE

    GrPlot(dc,pp->x,pp->y);
  }
}
CD3 *p_2CD3(F64 x=0,F64 y=0,F64 z=0)
{//Return a CD3 from a given x,y,z
  CD3 *ret=MAlloc(sizeof(CD3));

  ret->x=x;
  ret->y=y;
  ret->z=z;

  return ret;
}

U0 spherize(PARTICLE *z)
{//Convert to polar coordinates
  z->pr=Sqrt(z->x*z->x+z->y*z->y+z->z*z->z);
  z->pt=ATan2(Sqrt(z->x*z->x+z->y*z->y),z->z);
  z->pp=ATan2(z->y,z->x);
}

F64 Lerp(F64 a,F64 b,F64 t)
{//Linearly interpolate between two points
  return a+t*(b-a);
}
F64 Dist(F64 a,F64 b)
{//Distance Squared
  return a*a+b*b;
}
F64 DistSqrt(F64 a,F64 b)
{//Distance
  return Sqrt(Dist(a,b));
}
F64 DistTaxi2(F64 x1,F64 y1,F64 x2,F64 y2){
  return Abs(x2-x1)+Abs(y2-y1);
}
F64 DistTaxi(CD3 *p1,CD3 *p2)
{//Manhattan distance between two points
  return DistTaxi2(p1->x,p1->y,p2->x,p2->y);
}

/*CD3 a,aa;

a.x=a.y=10;
aa.x=aa.y=20;

U64 dx=Abs(a.x-aa.x),
    dy=Abs(a.y-aa.y);

"DistTaxi         : %2.8f\n",DistTaxi(&a,&aa);
"D3Dist    (Terry): %2.8f\n",D3Dist(&a,&aa);
"DistSqrt         : %2.8f\n",DistSqrt(dx,dy);

"D3DistSqr (Terry): %2.8f\n",D3DistSqr(&a,&aa);
"Dist             : %2.8f\n\n",Dist(dx,dy);
*/

U0 rot_base(CD3 *rp,F64 *ux,F64 *uy,F64 *uz)
{
  F64 cos_x=Cos(rotation_x),
       cos_y=Cos(rotation_y),
       sin_x=Sin(rotation_x),
       sin_y=Sin(rotation_y),
          y1=cos_x*rp->y-sin_x*rp->z,
          z1=sin_x*rp->y+cos_x*rp->z,
          x2=cos_y*rp->x+sin_y*z1,
          z2=-sin_y*rp->x+cos_y*z1;

  *ux=x2;*uy=y1;*uz=z2;
}
U0 rot_plot2(CD3 *rp,CD3 *up)
{
  rot_base(&rp,&up->x,&up->y,&up->z);
};
U0 rot_plot(PARTICLE *rp)
{//Rotate a PARTICLE
  F64 x,y,z;

  rot_base(rp,&x,&y,&z);

  rp->x=x;rp->y=y;rp->z=z;
}
