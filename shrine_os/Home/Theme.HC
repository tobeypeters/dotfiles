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

// colorhexa.com
//  0x63638c8c8080, // Spearmint
//  0xe2e280808a8a, // Honeysuckle
//  0xefef7c7c8e8e, // Hot Pink
//  0x808000002020, // Burgundy

#include "~/tp_Compositor.HC"

public CBGR48 gr_palette_test[COLORS_NUM]={
  0x00002b2b3636,0x070736364242,0x000080808080,0x31318282a4a4,
  0xcbcb4b4b1616,0x9c9c3636b6b6,0x858599990000,0xeeeee8e8d5d5,
  0x9393a1a1a1a1,0x26268b8bd2d2,0x4f4fb6b63636,0x2a2aa1a19898,
  0xdcdc32322f2f,0xd3d336368282,0xeeeeeeeeeeee,0xeeeee8e8d5d5
};

public CBGR48 gr_palette_gruv[COLORS_NUM]={
  0xf0f0eaead6d6, // MOUSE, CURSOR - BLACK
  0xffffffffffff, // BORDERS - BLUE
  0xf4f4b7b70000, // COMMENTS - GREEN
  0x0000ffffffff, // TYPES - CYAN
  0xb3b300002d2d, // RED
  0x16167a7abfbf, // PURPLE
  0x868654541111, // BROWN
  0x0000a4a4dbdb, // BRACES - LTGRAY
  0xe2e280808a8a, // DKGRAY
  0x30304c4c3434, // Folders, RETURNTYPES - LTBLUE
  0x000000000000, // LTGREEN
  0xb3b300002d2d, // LTCYAN
  0xffff00000000, // ERRORS-LTRED
  0x1e1e00000707, // SELECTION FG - LTPURPLE
  0x000000000000, // MENU TEXT, SCROLLBARGRIPPERS - YELLOW
  0x020202020000  // BG MAIN - WHITE
};

GrPaletteSet(gr_palette_gruv);

// NOTE: for whatever reason when you Abort&Exit (Shift+Esc)
// a User Task (usually a terminal) the theme may reset to
// gr_palette_std. I could not figure out why and how to fix that.
// So I just made gr_palette_std to be gr_palette_gruv.
MemCpy(gr_palette_std, gr_palette_gruv, sizeof(gr_palette_gruv));
