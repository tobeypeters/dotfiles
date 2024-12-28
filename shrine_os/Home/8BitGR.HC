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
#include "strings"
#include "~/td/utils"

#define BLKCNT 255
#define BLKSIZE 11

U8 *blocks[BLKCNT][BLKSIZE];
*blocks=CAlloc(sizeof(U8)*BLKCNT*BLKSIZE);

blocks[32][0]="LTGRAY"; //space
blocks[48][0]="LTBLUE"; //0
blocks[99][0]="LTCYAN"; //c
blocks[120][0]="BLUE"; //x
blocks[124][0]="RED"; //|

blocks[98][0]="BLACK"; //b <-black
blocks[119][0]="WHITE"; //w <-white
blocks[116][0]="LTCYAN"; //t <-"transparent"

U0 gen_gr(U8 *res=NULL) {
  U8 *prev_chr='\0';

  U64 x=0,y=0;

  "\n";
  "$$GREEN$$----BEGIN Graphic Resource definition----$$FG$$\n";
  while(*res) {
    x=x-(8*(x==8));

    if (!str_cmp(prev_chr,res[0])) {
      zFree(prev_chr);
      prev_chr=strnew(res[0]);

      "Color{%s};\n",blocks[res[0]][0];
    }

    "Pt{(%d,%d)};\n",x,y;

    if (++x==8) y++;

    res++;
  }
  "$$GREEN$$----END Graphic Resource definition----$$FG$$\n";
  "\n";

  zFree(prev_chr);
  return;
}

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
"warrior";gen_gr(warrior);

U8 *shield=strnew(,,
  "0 000 0 ",
  "00   00 ",
  "0  0  0 ", 
  "0 0x0 0 ",
  "0  0  0 ",
  "0  0  0 ",
  " 0   0  ",
  "  000   "
);
"shield";gen_gr(shield);

U8 *cross=strnew(,,
  "cccccccc",
  "ccc cccc",
  "ccc0cccc", 
  "c 0c0 cc",
  "ccc0cccc",
  "ccc cccc",
  "ccc cccc",
  "cccccccc"
);
"cross";gen_gr(cross);

/*
     xx
    xxxx
    xx x x
    x   xx
   xxxxxxx
  xxxxxx x
  xx xx x
  x xxx 
*/
U8 *ghost=strnew(,,
 "ccc00ccc",
 "cc0000cc",
 "cc00c0c0",
 "cc0ccc00",
 "c0000000",
 "000000c0",
 "00c00c0c",
 "0c000ccc"
);
"ghost";gen_gr(ghost);

U8 *grip=strnew(,,
 "        ",
 "  w  w  ",
 "  wb wb ",
 "  wb wb ",
 "  wb wb ",
 "  wb wb ",
 "  wb wb ",
 "  bb bb "
);
"grip";gen_gr(grip);

U8 *cross2=strnew(,,
 "   b    ",
 "   bw   ",
 "bbbbbbb ",
 " wwbwwww",
 "   bw   ",
 "   bw   ",
 "    w   ",
 "        "
);
"cross2";gen_gr(cross2);

zFree(blocks);

 