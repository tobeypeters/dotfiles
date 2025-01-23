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
      Generates a group of flocking boids.
  Resources:
      https://en.wikipedia.org/wiki/Boids
*/
#define  WIDTH GR_WIDTH
#define HEIGHT GR_HEIGHT

#define NUM_BOIDS 1000
#define MAX_SPEED 8
#define VIEW_RADIUS 50
#define SEPARATION_RADIUS 8

#define COHESION_FACTOR 0.01
#define ALIGNMENT_FACTOR 0.05
#define SEPARATION_FACTOR 0.1

class BOID {
  F64 x,y, // Position
    vx,vy, // Velocity
   leader;
};

BOID boids[NUM_BOIDS];
BOID *bpi,*bpj;

U64 i,j,bvx,bvy,sl=2,count;

F64 angle_1=ã/3,
    angle_2=-ã/3,
    avgVx,avgVy,
    repelX,repelY,
    px1,py1,px2,py2,
    bx,by,lp,cx,cy,
    distance,dx,dy,
    speed,scale;

U0 AnimateTask(I64)
{
  while (TRUE)
  {
    for (i=0;i<NUM_BOIDS;i++)
    {
      cx=0,cy=0,         // Cohesion
      avgVx=0,avgVy=0,   // Alignment
      repelX=0,repelY=0; // Separation

      count=0;

      bpi=&boids[i];

      for (j=0;j<NUM_BOIDS;j++)
      {
        if (i==j) goto continue;

        bpj=&boids[j];

        dx=bpi->x-bpj->x;
        dy=bpi->y-bpj->y;

          /*This makes it seem to flock more correctly. Less CPU usage.*/
//        distance=dx*dx+dy*dy;
//        if (distance<VIEW_RADIUS*VIEW_RADIUS)

        distance=Sqrt(dx*dx+dy*dy);
        if (distance<VIEW_RADIUS)
        {
          cx+=bpj->x;
          cy+=bpj->y;
          avgVx+=bpj->vx;
          avgVy+=bpj->vy;
          count++;

          if (distance<SEPARATION_RADIUS) {
            repelX-=bpj->x-bpi->x;
            repelY-=bpj->y-bpi->y;
          }
        }
        continue:
      }

      if (count)
      {
        //Cohesion
        cx/=count;cy/=count;
        bpi->vx+=(cx-bpi->x)*COHESION_FACTOR;
        bpi->vy+=(cy-bpi->y)*COHESION_FACTOR;

        //Alignment
        avgVx/=count;avgVy/=count;
        bpi->vx+=(avgVx-bpi->vx)*ALIGNMENT_FACTOR;
        bpi->vy+=(avgVy-bpi->vy)*ALIGNMENT_FACTOR;

        //Separation
        bpi->vx+=repelX*SEPARATION_FACTOR;
        bpi->vy+=repelY*SEPARATION_FACTOR;
      }

      //Speed
      speed=Sqrt(bpi->vx*bpi->vx+
                 bpi->vy*bpi->vy);

      if (speed>MAX_SPEED) {
        scale=MAX_SPEED/speed;
        bpi->vx*=scale;bpi->vy*=scale;
      }

      //Position
      bpi->x+=bpi->vx;
      bpi->y+=bpi->vy;

      //Bounds checks
      if (bpi->x<1) bpi->vx=Abs(bpi->vx);
      if (bpi->x>WIDTH-1) bpi->vx=-bpi->vx;
      if (bpi->y<1) bpi->vy=Abs(bpi->vy);
      if (bpi->y>HEIGHT-1) bpi->vy=-bpi->vy;
    }

    Sleep(20);
  }
}

U0 DrawIt(CTask *task,CDC *dc)
{
  dc->color=LTGREEN;

  for(i=0;i<NUM_BOIDS;i++)
  {
    if (i>NUM_BOIDS/3) dc->color=LTBLUE;
    if (i>(NUM_BOIDS/3)*2) dc->color=LTRED;

    bx=boids[i].x; by=boids[i].y;
    bvx=boids[i].vx; bvy=boids[i].vy;

    //Normalize
    lp=Sqrt(bvx*bvx+bvy*bvy);
    bvx=bvx/lp; bvy=bvy/lp;
    //Scale
    bvx=bvx*sl; bvy=bvy*sl;

    px1=-(bvx*Cos(angle_1)-bvy*Sin(angle_1))+bx;
    py1=-(bvx*Sin(angle_1)+bvy*Cos(angle_1))+by;
    px2=-(bvx*Cos(angle_2)-bvy*Sin(angle_2))+bx;
    py2=-(bvx*Sin(angle_2)+bvy*Cos(angle_2))+by;

    GrLine(dc,bx,by,px1,py1);
    GrLine(dc,px1,py1,px2,py2);
    GrLine(dc,px2,py2,bx,by);

//    GrPlot(dc,boids[i].x,boids[i].y); //little dot
//    GrCircle(dc,boids[i].x,boids[i].y,1); //big dot :>
  }
}

U0 Init()
{
  MemSet(boids,0,sizeof(boids));

  for (i=0;i<NUM_BOIDS;i++)
  {
    bpi=&boids[i];
    bpi->x=RandU16%WIDTH;
    bpi->y=RandU16%HEIGHT;
    bpi->vx=(RandU16%200-100)/100;
    bpi->vy=(RandU16%200-100)/100;
  }
}

I64 arg1,arg2,sc;

MenuPush(
  "File {"
  "  Abort(,CH_SHIFT_ESC);"
  "  Exit(,CH_ESC);"
  "}"
  "Play {"
  "  Restart(,'\n');"
  "}"
);

SettingsPush;
AutoComplete;
WinBorder; WinMax;
DocCursor; DocClear;

//Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",mp_cnt-1,Fs);
Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",,Fs);
Fs->draw_it=&DrawIt;

Init;

Bool run=TRUE;
try {
  while (run) {
    sc=GetMsg(&arg1,&arg2,1<<MSG_KEY_DOWN);
    switch (sc) {
      case MSG_KEY_DOWN:
        if (arg1=='\n') Init;
        if (arg1==CH_SHIFT_ESC||arg1==CH_ESC)
          run=FALSE;
    }
  }
} catch
  PutExcept;

SettingsPop;
MenuPop;
$LK,"",A="FI:"$