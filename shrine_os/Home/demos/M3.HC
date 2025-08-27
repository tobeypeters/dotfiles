Cd(__DIR__);

class BITMAPCOMB {
// --- BITMAP HEADER --------
    U16 bfType;      // File type ("BM")
    U32 bfSize;      // Size of the file in bytes
    U16 bfReserved1; // Reserved, must be 0
    U16 bfReserved2; // Reserved, must be 0
    U32 bfOffBits;   // Offset to start of pixel data

// --- BITMAP INFO --------
    U32 biSize;          // Size of this header (40 bytes)
    I32 biWidth;         // Image width
    I32 biHeight;        // Image height
    I16 biPlanes;        // Number of planes (must be 1)
    U16 biBitCount;      // Bits per pixel (e.g., 24 for RGB)
    U32 biCompression;   // Compression type
    U32 biSizeImage;     // Image size (may be 0 for uncompressed)
    I32 biXPelsPerMeter; // Horizontal resolution
    I32 biYPelsPerMeter; // Vertical resolution
    U32 biClrUsed;       // Colors in color table
    U32 biClrImportant;  // Important colors

} *bc;
bc=CAlloc(sizeof(BITMAPCOMB));

U8 *pbuff;

I64 x,y,dw,dh;
U0 bitmaptest() //Only wrapped this in a function, so I could use goto. :>
{
  U8 *buffer=FileRead("pa.bmp");

  MemCpy(bc,buffer,sizeof(BITMAPCOMB));
  "\n";
  "---- Bitmap Combined Info ----\n";
  "       File type: %d %c%c : %c%c\n",bc->bfType,buffer[0], buffer[1], bc->bfType.u8[0],bc->bfType.u8[1];
  "         Size of: %d bytes\n",bc->bfSize;
  "       Reserved1: %d\n",bc->bfReserved1;
  "       Reserved2: %d\n",bc->bfReserved2;
  "      Pix Offset: %d\n",bc->bfOffBits;
  "     Header size: %d\n",bc->biSize;
  "     Image Width: %d px\n",bc->biWidth;
  "    Image Height: %d px\n",bc->biHeight;
  "   Num of Planes: %d\n",bc->biPlanes;
  "  Bits Per Pixel: %d\n",bc->biBitCount;
  "Compression Type: %d\n",bc->biCompression;
  "      Image size: %d\n",bc->biSizeImage;
  "  Horizontal res: %d\n",bc->biXPelsPerMeter;
  "    Vertical res: %d\n",bc->biYPelsPerMeter;
  " Colors in table: %d\n",bc->biClrUsed;
  "Important colors: %d\n",bc->biClrImportant;
  "------------------------------\n";
  "\n";

  //Make sure it's type is BM & it's a 24bit bitmap.
  if (!bc->bfType==19778||
      !bc->biBitCount==24) goto halt;

  U8 *rbuff;

  I64 nearest=0,bestdiff=256,
     brightness,diff,width,
     height,rpad,bp=0,i,x,y,r,g,b;

  U8 greyscale[16];
  for (i=0;i<16;i++)
    greyscale[i]=i*255/15;

  dw=width=bc->biWidth;
  dh=height=bc->biHeight;
  rpad=(width*3+3)&(~3);

  bp+=bc->bfOffBits;

  rbuff=CAlloc(rpad);
  pbuff=CAlloc(width*height);

  for (y=height-1;y>=0;y--)
  {
    MemCpy(rbuff,buffer+bp,rpad);

    for (x=0;x<width;x++)
    {
      b=rbuff[x*3+0];
      g=rbuff[x*3+1];
      r=rbuff[x*3+2];

      brightness=ToI64(0.299*r+0.587*g+0.114*b);

      nearest=0;bestdiff=256;
      for (i=0;i<16;i++)
      {
        diff=Abs(brightness-greyscale[i]);
        if (diff<bestdiff) { bestdiff=diff; nearest=i; }
      }

      pbuff[y*width+x]=nearest;
    }
    bp+=rpad;
  }

  GetKey;

  halt:

  Free(rbuff);
  Free(buffer);
}


U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);
  dc->color=LTRED;

  for (y=dh-1;y>=0;y--)
  {
    for (x=0;x<dw;x++)
    {
      dc->color=pbuff[y*dw+x];

      GrPrint(dc,x*FONT_WIDTH,y*FONT_HEIGHT,"Û");
    }
  }
}

SettingsPush;
WinBorder;WinMax;
AutoComplete;
DocClear;

Fs->draw_it=&DrawIt;

GrPaletteSet(gr_palette_gray);

bitmaptest;

GrPaletteSet(gr_palette_std);

Free(pbuff);
Free(bc);

SettingsPop;

//Exit;
