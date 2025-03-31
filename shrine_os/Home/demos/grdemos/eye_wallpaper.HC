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

I64 ita,itb;

U64 bitdex(U64 x,U64 y) return y*8+x;
U0 EyeWall(CTask *task)
{
  CDC *dc2=DCAlias(gr.dc2,task);

  CCPU *c;

  U64 px,py,chr=127,c_percent,pos,
      cb=FONT_WIDTH*2+1;

  F64 angle=0;

  CDateStruct ds;
  Date2Struct(&ds,Now+local_time_offset);

  text.font[chr]=base_eye[0](U64);

  angle=ATan2(ms.pos.y/(GR_HEIGHT/8)-4,
                ms.pos.x/(GR_WIDTH/8)-4);

  px=4+Cos(angle)*2; py=4+Sin(angle)*2;    

  Btr(&text.font[chr],bitdex(px,py));
  Btr(&text.font[chr],bitdex(px+1,py));
  Btr(&text.font[chr],bitdex(px,py+1));
  Btr(&text.font[chr],bitdex(px+1,py+1));

  pos=1;
  GrPrint(dc2,pos,0,"%c",chr);

  pos=GR_WIDTH-(FONT_WIDTH*17)-1;
  GrPrint(dc2,pos,0,"%3tZ%02d/%02d%02d:%02d%s",
	  ds.day_of_week,"ST_DAYS_OF_WEEK",ds.mon,ds.day_of_mon,
	  ds.hour,ds.min,AMPM[ds.hour<12||ds.hour==24]);  

/*  if (scrncast.record)
    TextPrint(Fs,44-4,0,LTGRAY<<4+BLACK,"*");

*/
  pos-=FONT_WIDTH;
  for (ita=mp_cnt-1;ita>=0;ita--)
  {
    c=&cpu_structs[ita];

    c_percent=100.0*(1.0-c->idle_factor);
    
    pos-=cb; 

if (ita==0||c_percent)
    GrPrint(dc2,pos,0,"%2d",c_percent);
  }

  pos-=(FONT_WIDTH*3);
  GrPrint(dc2,pos,0,"CPU");
}

gr.fp_wall_paper=&EyeWall;
