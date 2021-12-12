public CBGR48 gr_palette_test[COLORS_NUM]={
  //0xeeeee8e8d5d5 0xb5b589890000
  0x00002b2b3636,0x070736364242,0x000080808080,0x31318282a4a4,
  0xcbcb4b4b1616,0x9c9c3636b6b6,0x858599990000,0xeeeee8e8d5d5,
  0x9393a1a1a1a1,0x26268b8bd2d2,0x4f4fb6b63636,0x2a2aa1a19898,
  0xdcdc32322f2f,0xd3d336368282,0xeeeeeeeeeeee,0xeeeee8e8d5d5
};

public CBGR48 gr_palette_gruv[COLORS_NUM]={
  0xf0f0eaead6d6, // BLACK
  0xe0e0e0e0e1e1, // BORDERS - BLUE
  0x000099990000, // COMMENTS - GREEN
  0x00007474cccc, // TYPES - CYAN

  0xcccc24241d1d, // RED
  0x16167a7abfbf, // PURPLE
  0x7c7c6f6f6464, // BROWN
  0x2d2d2d2d3030, // LTGRAY
  0x505049494545, // DKGRAY

  0x00007474cccc, // LTBLUE
  0x000000000000, // LTGREEN
  0x8e8ec0c07c7c, // LTCYAN

  0xfbfb49493434, // LTRED
  0xd3d386869b9b, // LTPURPLE

  0x000000000000, // MENU TEXT - YELLOW

  0x000000000000  // BG MAIN - WHITE
};

GrPaletteSet(gr_palette_gruv);

// NOTE: for whatever reason when you Abort&Exit (Shift+Esc)
// a User Task (usually a terminal) the theme may reset to
// gr_palette_std. I could not figure out why and how to fix that.
// So I just made gr_palette_std to be gr_palette_gruv.
MemCpy(gr_palette_std, gr_palette_gruv, sizeof(gr_palette_gruv));
