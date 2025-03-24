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
U0 theme3()
{//Standard VGA Palette
  rgb2_CBGR48(&gr_palette_vga[BLACK],15,21,27);
  rgb2_CBGR48(&gr_palette_vga[BLUE],0,0,95);
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

public CBGR48 amicus[COLORS_NUM] = {
0x0, 0x1A4883, 0x8D2E75, 0xFFA995, 0xA10000, 0xFFC0FF, 0x8B5858, 0xB2B6AF, 0x555753, 0xE4D2, 0x82BC49, 0x8AE0C0, 0xDF2100, 0xB800B2, 0xFFFFFF, 0x969696
};
public CBGR24 commander[COLORS_NUM] = {
0xFFFFFF, 0x867ADE, 0xCC55, 0x5A878B, 0xFF0000, 0xCC44CC, 0xDD8855, 0xE1E1E2, 0x777777, 0x9BFF, 0xAAFF66, 0xAAFFEE, 0xFF7777, 0xCA94E8, 0xEEEE77, 0x483AA7
};
public CBGR24 sandy_beach[COLORS_NUM] = {
0x000000, 0x000088, 0x008800, 0x006060, 0x002288, 0x4B0082, 0xA52A2A, 0xAAAAAA, 0x444444, 0x4169E1, 0xADFF2F, 0x00AAAA, 0xFF8888, 0x9932CC, 0xC09020, 0xFFF8DF
};
public CBGR24 slate[COLORS_NUM] = {
0xE3E3E3, 0x4F84A6, 0x73A255, 0x297582, 0xB34F4B, 0x8A52C3, 0xB7822F, 0x444444, 0x6D6D6D, 0x94BFDE, 0xA1CE97, 0x6DB4BE, 0xE88E88, 0xCA94E8, 0xD4B475, 0x1F1F1F
};
public CBGR24 temple[COLORS_NUM] = {
0x0, 0xAA, 0xAA00, 0xAAAA, 0xAA0000, 0xAA00AA, 0xAA5500, 0xAAAAAA, 0x555555, 0x5555FF, 0x55FF55, 0x55FFFF, 0xFF5555, 0xFF55FF, 0xFFFF55, 0xFFFFFF
};
public CBGR24 tradition[COLORS_NUM] = {
0xE8E8E9, 0x374B88, 0x4FBC2C, 0x29CACE, 0xDD0000, 0x8C33FF, 0x875721, 0x7F7A7C, 0x15171C, 0x2EA1FF, 0x4FFF00, 0xFFBB, 0x690000, 0x6E3FFC, 0xFFCC00, 0xC0F14
};
public CBGR24 vapor[COLORS_NUM] = {
0xE3E3E3, 0x3284F0, 0x55587C, 0xBF3584, 0xB34F4B, 0x9EE9EF, 0xD2865B, 0x444444, 0x6D6D6D, 0x8BD2B7, 0xA1CE97, 0xCB99CD, 0xE88E88, 0xFDBEA4, 0xFF8F9D, 0x2A1B39
};
public CBGR24 zsnes[COLORS_NUM] = {
0xE8E8E9, 0x374B88, 0x6C84FC, 0x297582, 0x63D64E, 0x397AFF, 0xB7822F, 0x25256E, 0x712, 0xFF2A76, 0xA1CE97, 0x6DB4BE, 0x9FA6FF, 0xCA94E8, 0xFFCC00, 0x132C
};

//theme1;
theme2;
//theme3;

set_theme(gr_palette_vga);

/*U8 *lst="amicus\0commander\0default1\0sandybeach\0slate\0temple\0tradition\0vapor\0zsnes\0";

public U64 pal_select()
{
  I64 ret=PopUpPickLst(lst);

  if (ret<0) return 0;

  U8 *pal=CAlloc(sizeof(U8)*64);

  U64 i=0,pos=0;

  while (*lst) {
    if (i==ret) break;
    lst+=StrLen(lst)+1;i++;
  }

  Free(pal);

  return 1;
}

public U0 pal_set(U8 *pal) {
  GrPaletteSet(pal);
  VGAFlush;
  MemCpy(gr_palette_std,pal,sizeof(pal)*COLORS_NUM);
}

if (pal_select) pal_set(lst);


//set_theme(amicus);

//CBGR48 test=GrPaletteColorGet(1);
//"test:%x\n",test;

//GrPaletteSet(gr_palette_custom);
//MemCpy(gr_palette_std,gr_palette_custom,sizeof(gr_palette_custom));
*/