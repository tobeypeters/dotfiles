Cd(__DIR__);;

#define PARTICLE_MAX 0

#include "grdefs"

class BOX {
  U64 x,y,width,height;
};

#define size 30

BOX *cbox=CAlloc(sizeof(BOX)),
    *mbox=CAlloc(sizeof(BOX));

//"%d %d %d %d\n",cbox->x,cbox->y,cbox->width,cbox->height;

Bool BoxCollide(BOX *a,BOX *b) {

return ToBool((a->x < b->x + b->width) &&
       (a->x + a->width > b->x) &&
       (a->y < b->y + b->height) &&
       (a->y + a->height > b->y));
}

U64 mx,my;

Bool detected=FALSE;

U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  mbox->x=mx=ms.pos.x;
  mbox->y=my=ms.pos.y-8;

  detected=BoxCollide(cbox,mbox);

  dc->color=YELLOW;

  GrPrint(dc,10,10,"mbox: %d %d",mbox->x,mbox->y);
  GrPrint(dc,10,20,"cbox: %d %d",cbox->x,cbox->y);

  GrRect(dc,mx,my,mbox->width,mbox->height);

  dc->color=LTGREEN;
  GrRect(dc,cbox->x,cbox->y,cbox->width,cbox->height);

  dc->color=LTRED;
  GrPrint(dc,10,50,"Detection: %d",detected);
  detected=FALSE;
}

U0 AnimateTask(I64) {}

U0 Init() {
  cbox->x=cbox->y=100;
  cbox->width=cbox->height=30;
  mbox->width=mbox->height=30;
}

//ANIMATE_TASK=FALSE;

Fs->win_inhibit|=WIG_DBL_CLICK;

#include "grmain"

p_init;

