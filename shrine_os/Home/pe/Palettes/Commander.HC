public CBGR24 gr_palette_commander[COLORS_NUM] = {
0xFFFFFF, 0x867ADE, 0xCC55, 0x5A878B, 0xFF0000, 0xCC44CC, 0xDD8855, 0xE1E1E2, 0x777777, 0x9BFF, 0xAAFF66, 0xAAFFEE, 0xFF7777, 0xCA94E8, 0xEEEE77, 0x483AA7
};
public U0 PaletteSetCommander()
{
  GrPaletteSet(gr_palette_commander);
  MemCpy(gr_palette_std,gr_palette_commander,sizeof(gr_palette_commander)*COLORS_NUM);
}
PaletteSetCommander;