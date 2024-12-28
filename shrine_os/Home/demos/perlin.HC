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

/*perlin.HC
  Description:
      Generates perlin noise. This is just one version.
  Resources:
      https://en.wikipedia.org/wiki/Perlin_noise
*/

#define WIDTH GR_WIDTH
#define HEIGHT GR_HEIGHT

#define GRID_SIZE 400

U64 pixels[WIDTH*HEIGHT];

U0 randomGradient(CD2 *p,U32 ix,U32 iy)
{//No precomputed gradients mean this works for all grid coordinates.
  U32 w=8*sizeof(U32),
      s=w/2,
       a=ix,
       b=iy;

  a=ToU32(a*3284157443);
  b=ToU32(b^(a<<s|a>>(w-s)));
  b=ToU32(b*1911520717);

  a^=(b<<s)|(b>>(w-s));
  a=ToU32(a*2048419325);

  F64 random=a*(ã/U32_MAX>>1);

  // Create the vector from the angle
  p->x=Sin(random);
  p->y=Cos(random);
}
F64 dotGridGradient(I64 ix,I64 iy,F64 x,F64 y)
{//Computes the dot product of the distance and gradient vectors.
 //Can't just use D3Dot();
  CD2 gradient;
  randomGradient(&gradient,ix, iy);

  //Compute the distance vector
  F64 dx=x-ix,
      dy=y-iy;

  return (dx*gradient.x + dy*gradient.y);
}
F64 interpolate(F64 a0,F64 a1,F64 w)
  return (a1-a0)*(3.0-w*2.0)*w*w+a0;

F64 perlin(F64 x,F64 y)
{//Sample Perlin noise at coordinates x, y
  I64 x0=x,
      y0=y,
   x1=x0+1,
   y1=y0+1;

  // Compute Interpolation weights
  F64 sx=x-x0,
       sy=y-y0;

  // Compute and interpolate top two corners
  F64 n0=dotGridGradient(x0,y0,x,y),
      n1=dotGridGradient(x1,y0,x,y),
     ix0=interpolate(n0,n1,sx);

  // Compute and interpolate bottom two corners
  n0=dotGridGradient(x0,y1,x,y);
  n1=dotGridGradient(x1,y1,x,y);
  F64 ix1=interpolate(n0,n1,sx);

  // Final step: interpolate between the two previously interpolated values, now in y
  F64 value=interpolate(ix0,ix1,sy);

  return value;
}
U0 Init()
{
  MemSet(pixels,0,sizeof(U64));

  U64 i,x,y;

  for (x=0;x<WIDTH;x++)
  {
    for (y=0;y<HEIGHT;y++)
    {
      I64 index=(y*WIDTH+x);

      F64 val=0,
         freq=1,
          amp=1;

      for (i=0;i<12;i++)
      {
        val+=perlin(x*freq/GRID_SIZE,y*freq/GRID_SIZE)*amp;

        freq*=2; amp/=2;
      }

      //Contrast
      val*=1.2;//1.2

      //Clipping
      if (val>1.0)
        val=1.0;
      else if (val<-1.0) val=-1.0;

      //Convert 1 to -1 into 255 to 0
      I64 color=ToI64((((val+1.0)*0.5)*15));

      // Set pixel color
      pixels[index] = color;
    }
  }

}
U0 DrawIt(CTask *task,CDC *dc)
{
  U64 i,x,y;

  for (x=0;x<WIDTH;x++)
  {
    for (y=0;y<HEIGHT;y++)
    {
      dc->color=pixels[(y*WIDTH+x)];
      GrPlot(dc,x,y);
    }
  }
}
U0 AnimateTask(I64)
{
}

I64 ch,sc;
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

GrPaletteSet(gr_palette_gray);
MemCpy(gr_palette_std,gr_palette_gray,sizeof(gr_palette_gray));

Init;

//Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",mp_cnt-1);
Fs->draw_it=&DrawIt;

try {
  do
    switch (ch=GetKey(&sc)) {
      case '\n':
        Init;
        break;
    }
  while (ch!=CH_ESC && ch!=CH_SHIFT_ESC);
}
catch
  PutExcept;

SettingsPop;
MenuPop;

GrPaletteSet(gr_palette_vga);
MemCpy(gr_palette_std,gr_palette_vga,sizeof(gr_palette_vga));

