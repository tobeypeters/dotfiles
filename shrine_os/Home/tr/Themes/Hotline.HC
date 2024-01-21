#include "~/Themes/Common.HC"

// #002b36
// #ff0087
// #00ffff
// #5fd7ff
// #d0d0d0
// #ffffff
// #fdf6e3
// #87ffff
// #5fafff
// #6fd9fc
// #00ffff
// #00ffaf
// #afffaf
// #d7ff00
// #ff5f00
// #ff0087
// #000000
// #121212

CBGR48 cust_palette[COLORS_NUM];
MakeColor(&cust_palette[BLACK],      255,255,255); // #ffffff
MakeColor(&cust_palette[BLUE],       255,0,135);   // #ff0087
MakeColor(&cust_palette[GREEN],      0,255,175);   // #00ffaf
MakeColor(&cust_palette[CYAN],       111,217,252); // #6fd9fc
MakeColor(&cust_palette[RED],        255,95,0);    // #ff5f00
MakeColor(&cust_palette[PURPLE],     253,246,227); // #fdf6e3
MakeColor(&cust_palette[BROWN],      215,255,0);   // #d7ff00
MakeColor(&cust_palette[LTGRAY],     0,43,54);     // #002b36
MakeColor(&cust_palette[LTBLUE],     95,215,255);  // #5fd7ff
MakeColor(&cust_palette[LTGREEN],    175,255,175); // #afffaf
MakeColor(&cust_palette[LTCYAN],     135,255,255); // #87ffff
MakeColor(&cust_palette[LTRED],      251,73,52);   // #afffaf
MakeColor(&cust_palette[LTPURPLE],   0,255,255);   // #00ffff
MakeColor(&cust_palette[YELLOW],     215,255,0);   // #d7ff00
MakeColor(&cust_palette[WHITE],      18,18,18);    // #121212

GrPaletteSet(cust_palette);
MemCpy(gr_palette_std, cust_palette, sizeof(cust_palette));
