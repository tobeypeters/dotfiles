U0 MakeColor(CBGR48* bgr, U8 r, U8 g, U8 b)
{
    bgr->r = ToI64(r*255);
    bgr->g = ToI64(g*255);
    bgr->b = ToI64(b*255);
}
