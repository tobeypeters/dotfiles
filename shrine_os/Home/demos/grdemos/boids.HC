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

/*boids.HC
  Description:
      Simulates flock(s) of boids.
  Resources:
      https://en.wikipedia.org/wiki/Boids
*/
Cd(__DIR__);;

#define PARTICLE_MAX 1000

#include "grdefs"

#define MAX_SPEED 8
#define VIEW_RADIUS 50
#define SEPARATION_RADIUS 8

#define COHESION_FACTOR 0.01
#define ALIGNMENT_FACTOR 0.05
#define SEPARATION_FACTOR 0.1

F64 ang1=M_PI/3,ang2=-ang1,count,
    bx,by,lp,px1,py1,px2,py2;

U64 bvx,bvy,sl=2;
U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  dc->color=LTGREEN;
  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];
    if (ita>PARTICLE_MAX/4) dc->color=LTBLUE;
    if (ita>(PARTICLE_MAX/4)*2) dc->color=LTRED;
    if (ita>(PARTICLE_MAX/4)*3) dc->color=YELLOW;

    bx=pp->x; by=pp->y;

    GrRegPoly(dc,bx,by,1,1,4);
    GrFloodFill(dc,bx,by);

/*  Manually draw a triangle
    bvx=pp->vx;bvy=pp->vy;

    //Normalize
    lp=Sqrt(bvx*bvx+bvy*bvy);
    bvx=bvx/lp;bvy=bvy/lp;
    //Scale
    bvx=bvx*sl;bvy=bvy*sl;

    px1=-(bvx*Cos(ang1)-bvy*Sin(ang1))+bx;
    py1=-(bvx*Sin(ang1)+bvy*Cos(ang1))+by;
    px2=-(bvx*Cos(ang2)-bvy*Sin(ang2))+bx;
    py2=-(bvx*Sin(ang2)+bvy*Cos(ang2))+by;

    GrLine(dc,bx,by,px1,py1);
    GrLine(dc,px1,py1,px2,py2);
    GrLine(dc,px2,py2,bx,by);
*/

//    GrPlot(dc,pp->x,pp->y); //little dot
//    GrCircle(dc,pp->x,pp->y,1); //big dot :>
  }
}

F64 count,cx,cy,distance,
    speed,scale,ax,ay,rx,ry;

U0 AnimateTask(I64)
{
  while (TRUE)
  {
    for (ita=0;ita<PARTICLE_MAX;ita++)
    {
      pp=&p_arr[ita];

      cx=cy=0; // Cohesion x,y
      ax=ay=0; // Alignment x,y
      rx=ry=0; // Separation x,y

      count=0;

      for (itb=0;itb<PARTICLE_MAX;itb++)
      {
        if (ita==itb) goto continue;

        ppp=&p_arr[itb];

        //Instead of doing something like spatial hashing.
        if (Abs(pp->x-ppp->x)>VIEW_RADIUS/2||
            Abs(pp->y-ppp->y)>VIEW_RADIUS/2) goto continue;

        //This makes it seem to flock more correctly. Less CPU usage.
        distance=D3Dist(pp,ppp);
        if (distance<VIEW_RADIUS)
        {
          cx+=ppp->x;
          cy+=ppp->y;
          ax+=ppp->vx;
          ay+=ppp->vy;
          count++;

          if (distance<SEPARATION_RADIUS) {
            rx-=ppp->x-pp->x;
            ry-=ppp->y-pp->y;
          }
        }
        continue:
      }

      if (count)
      {
        //Cohesion
        cx/=count;cy/=count;
        pp->vx+=(cx-pp->x)*COHESION_FACTOR;
        pp->vy+=(cy-pp->y)*COHESION_FACTOR;

        //Alignment
        ax/=count;ay/=count;
        pp->vx+=(ax-pp->vx)*ALIGNMENT_FACTOR;
        pp->vy+=(ay-pp->vy)*ALIGNMENT_FACTOR;

        //Separation
        pp->vx+=rx*SEPARATION_FACTOR;
        pp->vy+=ry*SEPARATION_FACTOR;
      }

      //Speed
      speed=DistSqrt(pp->vx,pp->vy);
      if (speed>MAX_SPEED) {
        scale=MAX_SPEED/speed;
        pp->vx*=scale;pp->vy*=scale;
      }

      //Position
      pp->x+=pp->vx;
      pp->y+=pp->vy;

      //Bounds checks
      if (pp->x<1) pp->vx=Abs(pp->vx);
      if (pp->x>WIDTH-1) pp->vx=-pp->vx;
      if (pp->y<1) pp->vy=Abs(pp->vy);
      if (pp->y>HEIGHT-1) pp->vy=-pp->vy;
    }

    Sleep(20);
  }
}

U0 Init()
{
  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];

    pp->x=RandU16%WIDTH;
    pp->y=RandU16%HEIGHT;
    pp->vx=(RandU16%200-100)/100;
    pp->vy=(RandU16%200-100)/100;
  }
}

U0 MS_L_DOWN(){}
U0 MS_L_UP(){}
U0 MS_MOVE(){}
U0 MS_MOVE_LDOWN(){}
U0 MS_MOVE_RDOWN(){}
U0 MS_R_DOWN(){}
U0 MS_R_UP(){}
U0 KEY_DOWN(){}

#define ANIMATE_TASK TRUE

#define MOUSE_TRAP FALSE

//Update mouse postion values,
//even when mouse button not pressed.
#define MOUSE_NODOWN FALSE

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);
