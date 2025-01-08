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
      Generates a group of flocking boids.
  Resources:
      https://en.wikipedia.org/wiki/Boids
*/
#define  WIDTH GR_WIDTH
#define HEIGHT GR_HEIGHT

#define NUM_BOIDS 1000
#define MAX_SPEED 8
#define VIEW_RADIUS 50
#define SEPARATION_RADIUS 8

class BOID {
  F64 x,y, // Position
    vx,vy; // Velocity
};

BOID boids[NUM_BOIDS];

U0 limit_speed(U64 idx) {
  BOID *bp=&boids[idx];
 
  F64 speed=Sqrt(bp->vx*bp->vx+
                 bp->vy*bp->vy);

  if (speed>MAX_SPEED) {
    bp->vx=(bp->vx/speed)*MAX_SPEED;
    bp->vy=(bp->vy/speed)*MAX_SPEED;
  }
}

U0 AnimateTask(I64)
{
  U64 i,j;

  while (TRUE)
  {
    for (i=0;i<NUM_BOIDS;i++)
    {
      F64 cx=0,cy=0,        // Cohesion
         avgVx=0,avgVy=0,   // Alignment
         repelX=0,repelY=0; // Separation

      I64 count=0;

      for (j=0;j<NUM_BOIDS;j++)
      {
        if (i==j) goto continue;

        F64 dx=boids[j].x-boids[i].x,
            dy=boids[j].y-boids[i].y,
            distance=Sqrt(dx*dx+dy*dy);

        if (distance<VIEW_RADIUS)
        {
          cx+=boids[j].x;
          cy+=boids[j].y;
          avgVx+=boids[j].vx;
          avgVy+=boids[j].vy;
          count++;

          if (distance<SEPARATION_RADIUS)
          {
            repelX-=dx;
            repelY-=dy;
          }
        }
        continue:
      }

      if (count>0)
      {
        //Cohesion
        cx/=count;
        cy/=count;
        boids[i].vx+=(cx-boids[i].x)*0.01;
        boids[i].vy+=(cy-boids[i].y)*0.01;

        //Alignment
        avgVx/=count;
        avgVy/=count;
        boids[i].vx+=(avgVx-boids[i].vx)*0.05;
        boids[i].vy+=(avgVy-boids[i].vy)*0.05;

        //Separation
        boids[i].vx+=repelX * 0.1;
        boids[i].vy+=repelY * 0.1;
      }

      limit_speed(i);

      // Update position
      boids[i].x+=boids[i].vx;
      boids[i].y+=boids[i].vy;

      // Wrap around screen
      if (boids[i].x<0) boids[i].x+=WIDTH;
      if (boids[i].x>=WIDTH) boids[i].x-=WIDTH;
      if (boids[i].y<0) boids[i].y+=HEIGHT;
      if (boids[i].y>=HEIGHT) boids[i].y-=HEIGHT;
    }

    Sleep(20);
  }
}

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(BLACK);

  dc->color=LTGREEN;

  U64 i;
  for(i=0;i<NUM_BOIDS;i++)
  {
    if (i>NUM_BOIDS/3) dc->color=LTBLUE;
    if (i>(NUM_BOIDS/3)*2) dc->color=LTRED;

    GrPlot(dc,boids[i].x,boids[i].y); //little dot
//    GrCircle(dc,boids[i].x,boids[i].y,1); //big dot :>
  }
}

U0 Init()
{
  MemSet(boids,0,sizeof(boids));

  U64 i;

  for (i=0;i<NUM_BOIDS;i++)
  {
    boids[i].x=RandU16%WIDTH;
    boids[i].y=RandU16%HEIGHT;
    boids[i].vx=(RandU16%200-100)/100;
    boids[i].vy=(RandU16%200-100)/100;
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
