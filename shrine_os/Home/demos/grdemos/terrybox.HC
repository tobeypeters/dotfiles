Cd(__DIR__);;

#include "skeleton"

I64 glbl_r[4][4];

U8 colors[3]={LTRED,LTBLUE,LTGREEN};

U0 DrawIt(CTask *,CDC *dc)
{
  I64 *old_r=dc->r,w=25;

  DCMat4x4Set(dc,glbl_r); //This assigns to dc->r and sets r_norm.

  dc->flags|=DCF_TRANSFORMATION;

  for (ita=0;ita<3;ita++)
  {
    dc->color=colors[ita];

    dc->x=w*ita+200;
    dc->y=w*ita+100;

    GrLine3(dc,-w,-w,-w, -w, w,-w);
    GrLine3(dc,-w, w,-w,  w, w,-w);
    GrLine3(dc, w, w,-w,  w,-w,-w);
    GrLine3(dc, w,-w,-w, -w,-w,-w);
    GrLine3(dc,-w,-w, w, -w, w, w);
    GrLine3(dc,-w, w, w,  w, w, w);
    GrLine3(dc, w, w, w,  w,-w, w);
    GrLine3(dc, w,-w, w, -w,-w, w);
    GrLine3(dc,-w,-w, w, -w,-w,-w);
    GrLine3(dc,-w, w, w, -w, w,-w);
    GrLine3(dc, w, w, w,  w, w,-w);
    GrLine3(dc, w,-w, w,  w,-w,-w);

    GrFloodFill(dc,dc->x,dc->y);
  }

  dc->r=old_r;
}

U0 Box()
{
  F64 aa=0,aaa=0,aaaa=0,s=1,s1=1.05;
  SettingsPush; //See $LK,"SettingsPush",A="MN:SettingsPush"$
  DocClear;
  Fs->draw_it=&DrawIt;
  while (!ScanChar) {
    Mat4x4IdentEqu(glbl_r);
    Mat4x4RotZ(glbl_r,aa);
    Mat4x4RotX(glbl_r,aaa);
//    Mat4x4RotZ(glbl_r,aaaa);
    Mat4x4Scale(glbl_r,s);

    Sleep(20);
    aa+=2*M_PI/70;
    aaa+=2*M_PI/90;
//    aaaa+=2*M_PI/110;
    s*=s1;
    if ( !(0.2<s<1.4) ) s1=1/s1;
  }
  SettingsPop;
}

Box;
