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

/*8BitGR.HC
  Description:
      Help build the text needed to build a 8x8 graphic resource.
  Usage:
      Construct an array like the one below, run this HC, and
      copy the output, go into the document you want the resource,
      Insert the graphic resource, In the graphics menu select
      "Sprite Edit Menu", then select "Edit as Text", and now
      you can paste your terminal output into this editor doc, exit
      out of all the editor docs, and you should be presented with your
      graphic.
*/

//Updated strnew: https://github.com/tobeypeters/dotfiles/blob/master/shrine_os/Home/td/strings.HC#L86
//zFree: https://github.com/tobeypeters/dotfiles/blob/master/shrine_os/Home/td/utils.HC#L104
#include "~/td/strings"
#include "~/td/utils"

U8 *warrior=strnew(,,
  "xxxxxx  ",
  " xxxxxx ",
  "xxx0|0x ",
  " xx0|0x ",
  " xx|0|x ",
  "  ||00  ",
  " xx||xx ",
  "  00x0  "
);

U8 *prev_chr='\0';
Bool changed=FALSE;

U64 x=0,y=0;

"\n";
while(*warrior) {
  x=x-(8*(x==8));

  if (changed=(!str_cmp(prev_chr,warrior[0]))) {
    zFree(prev_chr);
    prev_chr=strnew(warrior[0]);

    switch(warrior[0]) {
      case 32: //space
        "Color{TRANSPARENT};\n";
        break;
      case 48: //0
        "Color{LTRED};\n";
        break;
      case 120: //x
        "Color{BLACK};\n";
        break;
      case 124: //|
        "Color{WHITE};\n";
        break;
      default:
        break;
    }
  }

  "Pt{(%d,%d)};\n",x,y;

  if (++x==8) y++;

  warrior++;
}
"\n";

zFree(prev_chr);