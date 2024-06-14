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

/*pals.HC
  Description:
      Set system themes.
*/

public CBGR48 default1[COLORS_NUM]={
  0x00002b2b3636,0x070736364242,0x000080808080,0x31318282a4a4,
  0xcbcb4b4b1616,0x9c9c3636b6b6,0x858599990000,0xeeeee8e8d5d5,
  0x9393a1a1a1a1,0x26268b8bd2d2,0x4f4fb6b63636,0x2a2aa1a19898,
  0xdcdc32322f2f,0xd3d336368282,0xeeeeeeeeeeee,0xeeeee8e8d5d5
};
public CBGR24 amicus[COLORS_NUM]={
  0x0,0x1A4883,0x8D2E75,0xFFA995,0xA10000,0xFFC0FF,0x8B5858,0xB2B6AF,0x555753,
  0xE4D2,0x82BC49,0x8AE0C0,0xDF2100,0xB800B2,0xFFFFFF,0x969696
}; //ZealOS
public CBGR24 commander[COLORS_NUM]={
  0xFFFFFF,0x867ADE,0xCC55,0x5A878B,0xFF0000,0xCC44CC,0xDD8855,0xE1E1E2,0x777777,
  0x9BFF,0xAAFF66,0xAAFFEE,0xFF7777,0xCA94E8,0xEEEE77,0x483AA7
}; //ZealOS
public CBGR24 sandybeach[COLORS_NUM]={
  0x000000,0x000088,0x008800,0x006060,0x002288,0x4B0082,0xA52A2A,0xAAAAAA,
  0x444444,0x4169E1,0xADFF2F,0x00AAAA,0xFF8888,0x9932CC,0xC09020,0xFFF8DF
}; //ZealOS
public CBGR24 slate[COLORS_NUM]={
  0xE3E3E3,0x4F84A6,0x73A255,0x297582,0xB34F4B,0x8A52C3,0xB7822F,0x444444,
  0x6D6D6D,0x94BFDE,0xA1CE97,0x6DB4BE,0xE88E88,0xCA94E8,0xD4B475,0x1F1F1F
}; //ZealOS
public CBGR24 temple[COLORS_NUM]={
  0x0,0xAA,0xAA00,0xAAAA,0xAA0000,0xAA00AA,0xAA5500,0xAAAAAA,0x555555,
  0x5555FF,0x55FF55,0x55FFFF,0xFF5555,0xFF55FF,0xFFFF55,0xFFFFFF
}; //ZealOS
public CBGR24 tradition[COLORS_NUM]={
  0xE8E8E9,0x374B88,0x4FBC2C,0x29CACE,0xDD0000,0x8C33FF,0x875721,0x7F7A7C,
  0x15171C,0x2EA1FF,0x4FFF00,0xFFBB,0x690000,0x6E3FFC,0xFFCC00,0xC0F14
}; //ZealOS
public CBGR24 vapor[COLORS_NUM]={
  0xE3E3E3,0x3284F0,0x55587C,0xBF3584,0xB34F4B,0x9EE9EF,0xD2865B,0x444444,
  0x6D6D6D,0x8BD2B7,0xA1CE97,0xCB99CD,0xE88E88,0xFDBEA4,0xFF8F9D,0x2A1B39
}; //ZealOS
public CBGR24 zsnes[COLORS_NUM]={
  0xE8E8E9,0x374B88,0x6C84FC,0x297582,0x63D64E,0x397AFF,0xB7822F,0x25256E,
  0x712,0xFF2A76,0xA1CE97,0x6DB4BE,0x9FA6FF,0xCA94E8,0xFFCC00,0x132C
}; //ZealOS

U8 *lst="amicus\0commander\0default1\0sandybeach\0slate\0temple\0tradition\0vapor\0zsnes\0";

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
