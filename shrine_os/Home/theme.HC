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
/*CBGR48 gr_palette_default[COLORS_NUM]={
  0xFFFFFFFFFFFF,0x00000000AAAA,0x0000AAAA0000,0x0000AAAAAAAA,
  0xAAAA00000000,0xAAAA0000AAAA,0xAAAA55550000,0xAAAAAAAAAAAA,
  0x555555555555,0x55555555FFFF,0x5555FFFF5555,0x5555FFFFFFFF,
  0xFFFF55555555,0xFFFF5555FFFF,0xFFFFFFFF5555,0x000000000000
};*/
CBGR48 gr_palette_default[COLORS_NUM]={
  0xFFFFFFFFFFFF,0x00000000AAAA,0x0000AAAA0000,0x0000AAAAAAAA,
  0xAAAA00000000,0xAAAA0000AAAA,0xAAAA55550000,0xAAAAAAAAAAAA,
  0x555555555555,0x55555555FFFF,0x5555FFFF5555,0x5555FFFFFFFF,
  0xFFFF55555555,0xFFFF5555FFFF,0xFFFFFFFF5555,0x000000000000
};

CBGR48 gr_palette_vga[COLORS_NUM];
CBGR48 rr_palette_custom[COLORS_NUM];
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
   "arrays"...one for each theme.  There'll be a
   a function to set and list the available themes.
   Maybe after that, I'll switch it to allow for a
   theme folder and inside each file will be a theme 
   array.  We'll see.
 
*/
U0 rgb2_CBGR48(CBGR48* bgr,U64 r,U64 g,U64 b,F64 adj_percent=0)
{//Get a color: bgr->r = ToI64(r*255);
// Example: rgb2_CBGR48(&gr_palette_custom[GREEN],0,255,0, -0.65);

  I64 clamp_max = 65025;

  bgr->r = ClampI64(ToI64(r*(1+adj_percent)*255),0,clamp_max);
  bgr->g = ClampI64(ToI64(g*(1+adj_percent)*255),0,clamp_max);
  bgr->b = ClampI64(ToI64(b*(1+adj_percent)*255),0,clamp_max);
//  "%X %X %X %X\n",bgr->r,bgr->g,bgr->b,bgr;
}

U0 set_theme(CBGR48* in_pal)
{
  GrPaletteSet(in_pal);
  MemCpy(gr_palette_std,in_pal,sizeof(in_pal)*COLORS_NUM);
}

U0 default_theme() {
  PaletteSetStd;
}

U0 theme1()
{//Standard VGA Palette
  rgb2_CBGR48(&gr_palette_vga[BLACK],0,0,0);
  rgb2_CBGR48(&gr_palette_vga[BLUE],0,0,170); 
  rgb2_CBGR48(&gr_palette_vga[GREEN],0,170,0);
  rgb2_CBGR48(&gr_palette_vga[CYAN],0,170,170);
  rgb2_CBGR48(&gr_palette_vga[RED],170,0,0);
  rgb2_CBGR48(&gr_palette_vga[PURPLE],170,0,170);  //function names
  rgb2_CBGR48(&gr_palette_vga[BROWN],170,85,0);
  rgb2_CBGR48(&gr_palette_vga[LTGRAY],170,170,170);
  rgb2_CBGR48(&gr_palette_vga[LTBLUE],88,88,255);
  rgb2_CBGR48(&gr_palette_vga[LTGREEN],85,255,85);
  rgb2_CBGR48(&gr_palette_vga[LTCYAN],85,255,255);
  rgb2_CBGR48(&gr_palette_vga[LTRED],255,85,85);
  rgb2_CBGR48(&gr_palette_vga[LTPURPLE],255,85,255);
  rgb2_CBGR48(&gr_palette_vga[YELLOW],255,255,85);
  rgb2_CBGR48(&gr_palette_vga[WHITE],255,255,255,-.10);
}
U0 theme2()
{//Custom VGA Palette
  rgb2_CBGR48(&gr_palette_vga[BLACK],0,0,0);
  rgb2_CBGR48(&gr_palette_vga[BLUE],0,0,170,-.45); 
  rgb2_CBGR48(&gr_palette_vga[GREEN],0,170,0);
  rgb2_CBGR48(&gr_palette_vga[CYAN],0,170,170);
  rgb2_CBGR48(&gr_palette_vga[RED],170,0,0,-.35);
  rgb2_CBGR48(&gr_palette_vga[PURPLE],170,0,170);  //function names
  rgb2_CBGR48(&gr_palette_vga[BROWN],170,85,0);
  rgb2_CBGR48(&gr_palette_vga[LTGRAY],170,170,170);
  rgb2_CBGR48(&gr_palette_vga[LTBLUE],88,88,255);
  rgb2_CBGR48(&gr_palette_vga[LTGREEN],85,255,85);
  rgb2_CBGR48(&gr_palette_vga[LTCYAN],85,255,255);
  rgb2_CBGR48(&gr_palette_vga[LTRED],255,85,85,-.1);
  rgb2_CBGR48(&gr_palette_vga[LTPURPLE],255,85,255);
  rgb2_CBGR48(&gr_palette_vga[YELLOW],255,255,85,-.3);
  rgb2_CBGR48(&gr_palette_vga[WHITE],255,255,255,-.2);
}

//theme1;
theme2;

set_theme(gr_palette_vga);

//CBGR48 test=GrPaletteColorGet(1);
//"test:%x\n",test;

//GrPaletteSet(gr_palette_custom);
//MemCpy(gr_palette_std,gr_palette_custom,sizeof(gr_palette_custom));
