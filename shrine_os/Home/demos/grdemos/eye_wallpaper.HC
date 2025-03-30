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

/*eye.HC
  Description:
      Eye wallpaper.
*/
#help_index "Windows"

#define EYE_SIZE 64
#define PUPIL_SIZE 2

U8 base_eye[8] = {
    0b00111100,
    0b01111110,
    0b11111111,
    0b11111111,
    0b11111111,
    0b11111111,
    0b01111110,
    0b00111100
};

I64 ita,itb,cx=4,cy=4,dx,dy,px,py,pxp,pyp;
U0 EyeWall(CTask *task)
{
  CDC *dc2=DCAlias(gr.dc2,task);

//  CCPU *c;

  U64 chr=127;

  CDateStruct ds;
  Date2Struct(&ds,Now+local_time_offset);

  task->text_attr=LTGRAY<<4+BLACK;

  text.font[chr]=base_eye[0](U64);

  dx=(ms.pos.x)/(GR_WIDTH/8)-cx;
  dy=(ms.pos.y)/(GR_HEIGHT/8)-cy;

  if (dx<-2) dx=-2;
  if (dx>2) dx=2;
  if (dy<-2) dy=-2;

  if (dy>1) dy=1; // Restrict top movement to base_eye[4]

  px=dx+4;py=cy+dy;

  if (px>5) px=5;

  for (ita=-PUPIL_SIZE/2;ita<=PUPIL_SIZE/2;ita++)
  {
    for (itb=-PUPIL_SIZE/2;itb<=PUPIL_SIZE/2;itb++)
    {
      pxp=px+itb; pyp=py+ita;
      if (pxp>=0&&pxp<8&&pyp>=0&&pyp<8)
        Btr(&text.font[chr],(pyp*8)+pxp);
      else Bts(&text.font[chr],(pyp*8)+pxp);
    }
  }

  GrPrint(dc2,2,0,"%c",chr);

/*  if (scrncast.record)
    TextPrint(Fs,44-4,0,LTGRAY<<4+BLACK,"*");
  for (i=0;i<mp_cnt;i++) {
    c=&cpu_structs[i];
    if (i&1)
      TextPrint(Fs,44+i*2,0,LTGRAY<<4+BLACK,"%2tf",100.0*(1.0-c->idle_factor));
    else
      TextPrint(Fs,44+i*2,0,LTGRAY<<4+BLACK,"%2tf",100.0*(1.0-c->idle_factor));
  }
*/

  GrPrint(dc2,GR_WIDTH-(FONT_WIDTH*17)-2,0,"%3tZ%02d/%02d%02d:%02d%s",
	  ds.day_of_week,"ST_DAYS_OF_WEEK",ds.mon,ds.day_of_mon,
	  ds.hour,ds.min,AMPM[ds.hour<12||ds.hour==24]);  
}

gr.fp_wall_paper=&EyeWall;
