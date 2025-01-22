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

/*grdefs.HC
  Description:
      Graphics related stuff.
*/
#define WIDTH GR_WIDTH
#define HEIGHT GR_HEIGHT

class PARTICLE
{
  Bool active;
  F64 x,y,z; //Instead of using CD3
  U64 color;
};

U0 p_init2(PARTICLE *p)
{//Helper function for p_init
  p->active=FALSE;
  p->x=p->y=p->z=0;
//  p->color=WHITE;
  p->color=RandU16%COLORS_NUM;
}
U0 p_init(U8 *p,I64 p_cnt)
{
  PARTICLE *pp;
 
  for (p_cnt--;p_cnt>=0;p_cnt--)
  {
    pp=p+sizeof(PARTICLE)*p_cnt;
    p_init2(pp);
  }
}
U0 p_deinit(U8 *p,U64 p_cnt)
{
  MemSet(p,'\0',sizeof(PARTICLE)*p_cnt);
}


