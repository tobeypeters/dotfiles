// colorhexa.com
//  0x63638c8c8080, // Spearmint
//  0xe2e280808a8a, // Honeysuckle
//  0xefef7c7c8e8e, // Hot Pink
//  0x808000002020, // Burgundy

public CBGR48 gr_palette_test[COLORS_NUM]={
  //0xeeeee8e8d5d5 0xb5b589890000
  0x00002b2b3636,0x070736364242,0x000080808080,0x31318282a4a4,
  0xcbcb4b4b1616,0x9c9c3636b6b6,0x858599990000,0xeeeee8e8d5d5,
  0x9393a1a1a1a1,0x26268b8bd2d2,0x4f4fb6b63636,0x2a2aa1a19898,
  0xdcdc32322f2f,0xd3d336368282,0xeeeeeeeeeeee,0xeeeee8e8d5d5
};

public CBGR48 gr_palette_gruv[COLORS_NUM]={
  0xf0f0eaead6d6, // BLACK
  0xf8f8e2e2c6c6, // BORDERS - BLUE
  0x63638c8c8080, // COMMENTS - GREEN



  0xb5b5b5b5f0f0, // TYPES - CYAN
//  0xd7d7e6e6fafa // TYPES - CYAN



  0xb3b300002d2d, // RED


  0x16167a7abfbf, // PURPLE

  0x868654541111, // BROWN


  0x020202020000, // LTGRAY
//  0x1e1e00000707, // LTGRAY
//  0x2d2d2d2d3030, // LTGRAY


  0x505049494545, // DKGRAY


  0x30304c4c3434, // Folders - LTBLUE

  0x000000000000, // LTGREEN


  0x8e8ec0c07c7c, // LTCYAN
  0x00000000ffff, // LTRED


  0x1e1e00000707, // SELECTION FG - LTPURPLE


  0x000000000000, // MENU TEXT - YELLOW
  0x020202020000  // BG MAIN - WHITE
};

GrPaletteSet(gr_palette_gruv);

// NOTE: for whatever reason when you Abort&Exit (Shift+Esc)
// a User Task (usually a terminal) the theme may reset to
// gr_palette_std. I could not figure out why and how to fix that.
// So I just made gr_palette_std to be gr_palette_gruv.
MemCpy(gr_palette_std, gr_palette_gruv, sizeof(gr_palette_gruv));
