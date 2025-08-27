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

U8 *buffer=FileRead("pa.bmp");
U64 bp=0;

MemCpy(bc,buffer,sizeof(BITMAPCOMB));
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

bp+=sizeof(BITMAPCOMB);

Free(bc);
Free(buffer);
