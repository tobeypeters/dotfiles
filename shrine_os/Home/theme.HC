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

//Color Resource: http://www.computerhope.com/htmcolor.htm

#include "~/tp_Compositor.HC"


/* colorhexa.com
  0xa4a4c6c63939, // Android Green
  0xf2f2f3f3f4f4, // Anti-flash White
  0x99996666cccc, // Amethyst
  0x9f9f81817070, // Beaver
  0x808000002020, // Burgundy
  0xe2e280808a8a, // Honeysuckle
  0xefef7c7c8e8e, // Hot Pink
  0x63638c8c8080, // Spearmint
  0xf8f8dede7e7e, // Mellow Yellow
  0x9a9acdcd3232, // Yellow Green
  0x6666ffff0000, // Bright Green
*/
CBGR48 gr_palette_default[COLORS_NUM]={
  0x00002b2b3636,0x070736364242,0x000080808080,0x31318282a4a4,
  0xcbcb4b4b1616,0x9c9c3636b6b6,0x858599990000,0xeeeee8e8d5d5,
  0x9393a1a1a1a1,0x26268b8bd2d2,0x4f4fb6b63636,0x2a2aa1a19898,
  0xdcdc32322f2f,0xd3d336368282,0xeeeeeeeeeeee,0xeeeee8e8d5d5
};

CBGR48 gr_palette_custom[COLORS_NUM];
/*
     [BLACK] MOUSE, CURSOR
      [BLUE] BORDERS
     [GREEN] COMMENTS
      [CYAN] TYPES
       [RED] FILE LINKS
    [PURPLE]
     [BROWN]
    [LTGRAY] BRACES
    [DKGRAY]
    [LTBLUE] FOLDERS,RETURN TYPES
   [LTGREEN]
     LTCYAN]
     [LTRED] ERRORS
  [LTPURPLE] SELECTIONFG
    [YELLOW] MENUTEXT, SCROLLBAR GRIPPERS
     [WHITE] BGMAIN
*/

/* This "theme1()" being a function will go away. I'll just have
   "structures"...one for each theme.  There'll be a
   a function to set and list the available themes.
   Maybe after that, I'll switch it to allow for a
   theme folder and inside it file will be a theme 
   structure.  We'll see.
 
*/
U0 rgb2_CBGR48(CBGR48* bgr,U64 r,U64 g,U64 b,F64 adj_percent=0)
{//Get a color: bgr->r = ToI64(r*255);
  I64 clamp_max = 65025;

  bgr->r = ClampI64(ToI64(r*(1+adj_percent)*255),0,clamp_max);
  bgr->g = ClampI64(ToI64(g*(1+adj_percent)*255),0,clamp_max);
  bgr->b = ClampI64(ToI64(b*(1+adj_percent)*255),0,clamp_max);
}

U0 set_theme(CBGR48 test)
{
  GrPaletteSet(test);
  MemCpy(gr_palette_std,test,sizeof(test));
}

U0 default_theme()
{
  PaletteSetStd;
}


U0 theme1()
{
  rgb2_CBGR48(&gr_palette_custom[BLACK],255,255,255);
  rgb2_CBGR48(&gr_palette_custom[BLUE],200,200,200);
  rgb2_CBGR48(&gr_palette_custom[GREEN],0,255,0, -0.65);
  rgb2_CBGR48(&gr_palette_custom[CYAN],128,128,0);
  rgb2_CBGR48(&gr_palette_custom[RED],200,200,200);
  rgb2_CBGR48(&gr_palette_custom[PURPLE],253,246,227);
  rgb2_CBGR48(&gr_palette_custom[BROWN],215,255,0);
  rgb2_CBGR48(&gr_palette_custom[LTGRAY],194,70,65);
  rgb2_CBGR48(&gr_palette_custom[LTBLUE],95,215,255);
  rgb2_CBGR48(&gr_palette_custom[LTGREEN],175,255,175);
  rgb2_CBGR48(&gr_palette_custom[LTCYAN],135,255,255);
  rgb2_CBGR48(&gr_palette_custom[LTRED],251,73,52);
  rgb2_CBGR48(&gr_palette_custom[LTPURPLE],0,255,255);
  rgb2_CBGR48(&gr_palette_custom[YELLOW],18,18,18);
  rgb2_CBGR48(&gr_palette_custom[WHITE],255,255,255,-.93);
}

theme1;

set_theme(gr_palette_custom);

//This works perfect.  If I do this here, the palette doesn't get
//reset if I close the window.
//GrPaletteSet(gr_palette_custom);
//MemCpy(gr_palette_std,gr_palette_custom,sizeof(gr_palette_custom));
