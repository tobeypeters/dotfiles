#include <SDL2/SDL.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* ========================================================= */
/* Config                                                    */
/* ========================================================= */

#define WIDTH 1280
#define HEIGHT 800

#define CHUNK_SIZE 16       // Number of blocks per chunk edge
#define WORLD_CHUNKS 4      // Chunks per axis
#define WORLD_SIZE (CHUNK_SIZE * WORLD_CHUNKS)  // Total world blocks

#define FOV 70.0f
#define SPEED 5.0f
#define SENS 0.0025f
#define NEARZ 0.1f

typedef struct { float x,y,z; } Vec3;
typedef struct { int x,y,z; } IVec3;

/* ========================================================= */
/* Renderer                                                  */
/* ========================================================= */
typedef struct {
    int w,h;
    Uint32* color;
    float* depth;
    bool wireframe;
    bool show_chunks;
    bool show_occluded;
} Renderer;

/* ========================================================= */
/* Blocks                                                    */
/* ========================================================= */
typedef enum {
    BLOCK_AIR = 0,
    BLOCK_GRASS,
    BLOCK_DIRT,
    BLOCK_STONE,
    BLOCK_WOOD,
    BLOCK_LEAVES,
    BLOCK_WATER,
    BLOCK_GLASS,
    BLOCK_SAND,
    BLOCK_BRICK,
    BLOCK_COUNT
} BlockType;

typedef struct {
    BlockType type;
    bool transparent;
    bool solid;
    Uint32 top_color;
    Uint32 side_color;
    Uint32 bottom_color;
} BlockData;

#define ARGB(a,r,g,b) ((a<<24)|(r<<16)|(g<<8)|b)

static BlockData block_types[BLOCK_COUNT] = {
    [BLOCK_AIR]    = {BLOCK_AIR, true,false, ARGB(0,0,0,0), ARGB(0,0,0,0), ARGB(0,0,0,0)},
    [BLOCK_GRASS]  = {BLOCK_GRASS,false,true, ARGB(255,78,143,56), ARGB(255,110,120,60), ARGB(255,139,69,19)},
    [BLOCK_DIRT]   = {BLOCK_DIRT,false,true, ARGB(255,139,69,19), ARGB(255,139,69,19), ARGB(255,139,69,19)},
    [BLOCK_STONE]  = {BLOCK_STONE,false,true, ARGB(255,128,128,128), ARGB(255,128,128,128), ARGB(255,128,128,128)},
    [BLOCK_WOOD]   = {BLOCK_WOOD,false,true, ARGB(255,139,69,19), ARGB(255,160,82,45), ARGB(255,160,82,45)},
    [BLOCK_LEAVES] = {BLOCK_LEAVES,true,true, ARGB(200,34,139,34), ARGB(200,34,139,34), ARGB(200,34,139,34)},
    [BLOCK_WATER]  = {BLOCK_WATER,true,false, ARGB(180,30,144,255), ARGB(180,30,144,255), ARGB(180,30,144,255)},
    [BLOCK_GLASS]  = {BLOCK_GLASS,true,true, ARGB(120,135,206,235), ARGB(120,135,206,235), ARGB(120,135,206,235)},
    [BLOCK_SAND]   = {BLOCK_SAND,false,true, ARGB(255,240,230,140), ARGB(255,240,230,140), ARGB(255,240,230,140)},
    [BLOCK_BRICK]  = {BLOCK_BRICK,false,true, ARGB(255,178,34,34), ARGB(255,178,34,34), ARGB(255,178,34,34)},
};

BlockType world[WORLD_SIZE][WORLD_SIZE][WORLD_SIZE];
unsigned int WORLD_SEED = 1337;

/* ========================================================= */
/* Font (5x7)                                               */
/* ========================================================= */
static const unsigned char font5x7[96][7] = {
/* 32 ' ' */ {0,0,0,0,0,0,0},
/* 33 '!' */ {4,4,4,4,0,0,4},
/* 34 '"' */ {10,10,0,0,0,0,0},
/* 35 '#' */ {10,31,10,10,31,10,0},
/* 36 '$' */ {4,15,20,14,5,30,4},
/* 37 '%' */ {17,18,4,8,19,17,0},
/* 38 '&' */ {12,18,20,8,21,18,13},
/* 39 ''' */ {6,4,8,0,0,0,0},
/* 40 '(' */ {2,4,8,8,8,4,2},
/* 41 ')' */ {8,4,2,2,2,4,8},
/* 42 '*' */ {0,10,4,31,4,10,0},
/* 43 '+' */ {0,4,4,31,4,4,0},
/* 44 ',' */ {0,0,0,0,6,4,8},
/* 45 '-' */ {0,0,0,31,0,0,0},
/* 46 '.' */ {0,0,0,0,0,6,6},
/* 47 '/' */ {1,2,4,8,16,0,0},
/* 48 '0' */ {14,17,19,21,25,17,14},
/* 49 '1' */ {4,12,4,4,4,4,14},
/* 50 '2' */ {14,17,1,2,4,8,31},
/* 51 '3' */ {31,2,4,2,1,17,14},
/* 52 '4' */ {2,6,10,18,31,2,2},
/* 53 '5' */ {31,16,30,1,1,17,14},
/* 54 '6' */ {6,8,16,30,17,17,14},
/* 55 '7' */ {31,1,2,4,8,8,8},
/* 56 '8' */ {14,17,17,14,17,17,14},
/* 57 '9' */ {14,17,17,15,1,2,12},
/* 58 ':' */ {0,6,6,0,6,6,0},
/* 59 ';' */ {0,6,6,0,6,4,8},
/* 60 '<' */ {2,4,8,16,8,4,2},
/* 61 '=' */ {0,0,31,0,31,0,0},
/* 62 '>' */ {8,4,2,1,2,4,8},
/* 63 '?' */ {14,17,1,2,4,0,4},
/* 64 '@' */ {14,17,19,21,19,16,14},
/* 65 'A' */ {14,17,17,31,17,17,17},
/* 66 'B' */ {30,17,17,30,17,17,30},
/* 67 'C' */ {14,17,16,16,16,17,14},
/* 68 'D' */ {30,17,17,17,17,17,30},
/* 69 'E' */ {31,16,16,30,16,16,31},
/* 70 'F' */ {31,16,16,30,16,16,16},
/* 71 'G' */ {14,17,16,23,17,17,15},
/* 72 'H' */ {17,17,17,31,17,17,17},
/* 73 'I' */ {14,4,4,4,4,4,14},
/* 74 'J' */ {7,2,2,2,2,18,12},
/* 75 'K' */ {17,18,20,24,20,18,17},
/* 76 'L' */ {16,16,16,16,16,16,31},
/* 77 'M' */ {17,27,21,17,17,17,17},
/* 78 'N' */ {17,25,21,19,17,17,17},
/* 79 'O' */ {14,17,17,17,17,17,14},
/* 80 'P' */ {30,17,17,30,16,16,16},
/* 81 'Q' */ {14,17,17,17,21,18,13},
/* 82 'R' */ {30,17,17,30,20,18,17},
/* 83 'S' */ {15,16,16,14,1,1,30},
/* 84 'T' */ {31,4,4,4,4,4,4},
/* 85 'U' */ {17,17,17,17,17,17,14},
/* 86 'V' */ {17,17,17,17,17,10,4},
/* 87 'W' */ {17,17,17,21,21,21,10},
/* 88 'X' */ {17,17,10,4,10,17,17},
/* 89 'Y' */ {17,17,10,4,4,4,4},
/* 90 'Z' */ {31,1,2,4,8,16,31},
/* 91 '[' */ {14,8,8,8,8,8,14},
/* 92 '\\'*/ {16,8,4,2,1,0,0},
/* 93 ']' */ {14,2,2,2,2,2,14},
/* 94 '^' */ {4,10,17,0,0,0,0},
/* 95 '_' */ {0,0,0,0,0,0,31},
/* 96 '`' */ {8,4,2,0,0,0,0},
/* 97 'a' */ {0,0,14,1,15,17,15},
/* 98 'b' */ {16,16,30,17,17,17,30},
/* 99 'c' */ {0,0,14,16,16,17,14},
/* 100 'd' */ {1,1,15,17,17,17,15},
/* 101 'e' */ {0,0,14,17,31,16,14},
/* 102 'f' */ {3,4,31,4,4,4,4},
/* 103 'g' */ {0,0,15,17,15,1,14},
/* 104 'h' */ {16,16,30,17,17,17,17},
/* 105 'i' */ {4,0,12,4,4,4,14},
/* 106 'j' */ {2,0,2,2,2,18,12},
/* 107 'k' */ {16,16,18,20,24,20,18},
/* 108 'l' */ {12,4,4,4,4,4,14},
/* 109 'm' */ {0,0,10,21,21,21,21},
/* 110 'n' */ {0,0,30,17,17,17,17},
/* 111 'o' */ {0,0,14,17,17,17,14},
/* 112 'p' */ {0,0,30,17,30,16,16},
/* 113 'q' */ {0,0,15,17,15,1,1},
/* 114 'r' */ {0,0,11,12,8,8,8},
/* 115 's' */ {0,0,14,16,14,1,30},
/* 116 't' */ {4,4,31,4,4,4,3},
/* 117 'u' */ {0,0,17,17,17,17,14},
/* 118 'v' */ {0,0,17,17,17,10,4},
/* 119 'w' */ {0,0,17,17,21,21,10},
/* 120 'x' */ {0,0,17,10,4,10,17},
/* 121 'y' */ {0,0,17,17,15,1,14},
/* 122 'z' */ {0,0,31,2,4,8,31},
/* 123 '{' */ {2,4,4,8,4,4,2},
/* 124 '|' */ {4,4,4,4,4,4,4},
/* 125 '}' */ {8,4,4,2,4,4,8},
/* 126 '~' */ {0,0,9,21,18,0,0},
};

/* ========================================================= */
/* Renderer helpers                                          */
/* ========================================================= */
static inline void r_clear(Renderer* r, Uint32 clear){
    for(int i=0;i<r->w*r->h;i++){
        r->color[i]=clear;
        r->depth[i]=1e9f;
    }
}

static inline void r_putpixel(Renderer* r,int x,int y,float z,Uint32 c){
    if(x<0||y<0||x>=r->w||y>=r->h) return;
    int i=x+y*r->w;
    if(z<r->depth[i]){
        r->depth[i]=z;
        r->color[i]=c;
    }
}

static inline void r_putpixel_hud(Renderer* r,int x,int y,Uint32 c){
    if(x<0||y<0||x>=r->w||y>=r->h) return;
    int i=x+y*r->w;
    if(-1.0f < r->depth[i]){
        r->depth[i] = -1.0f;
        r->color[i]=c;
    }
}

static void r_line(Renderer* r, int x0,int y0,float z0,int x1,int y1,float z1,Uint32 c){
    int dx=abs(x1-x0), dy=abs(y1-y0);
    int sx=(x0<x1)?1:-1, sy=(y0<y1)?1:-1;
    int err=dx-dy;
    while(1){
        float t=(dx>0)?(float)abs(x0-x1)/dx:0;
        float z=z0*(1-t)+z1*t;
        r_putpixel(r,x0,y0,z,c);
        if(x0==x1&&y0==y1) break;
        int e2=2*err;
        if(e2>-dy){err-=dy;x0+=sx;}
        if(e2<dx){err+=dx;y0+=sy;}
    }
}

void r_char(Renderer* r,int x,int y,char c,Uint32 col){
    if(c<32||c>126) return;
    const unsigned char* g=font5x7[c-32];
    for(int row=0;row<7;row++)
        for(int colb=0;colb<5;colb++)
            if(g[row]&(1<<(4-colb)))
                r_putpixel_hud(r,x+colb,y+row,col);
}

void r_text(Renderer* r,int x,int y,const char* s,Uint32 col){
    int start_x=x;
    while(*s){
        if(*s=='\n'){y+=8;x=start_x;}
        else{r_char(r,x,y,*s,col);x+=6;}
        s++;
    }
}

/* ========================================================= */
/* Triangle Renderer                                         */
/* ========================================================= */
void r_triangle(Renderer* r, Vec3 a, Vec3 b, Vec3 c, Uint32 col, float fov){
    if(a.z<=NEARZ||b.z<=NEARZ||c.z<=NEARZ) return;
    int x0=(int)((a.x/a.z)*fov + r->w*0.5f);
    int y0=(int)((-a.y/a.z)*fov + r->h*0.5f);
    int x1=(int)((b.x/b.z)*fov + r->w*0.5f);
    int y1=(int)((-b.y/b.z)*fov + r->h*0.5f);
    int x2=(int)((c.x/c.z)*fov + r->w*0.5f);
    int y2=(int)((-c.y/c.z)*fov + r->h*0.5f);
    if(r->wireframe){
        r_line(r,x0,y0,a.z,x1,y1,b.z,col);
        r_line(r,x1,y1,b.z,x2,y2,c.z,col);
        r_line(r,x2,y2,c.z,x0,y0,a.z,col);
        return;
    }
    int minx=fmax(0,fmin(x0,fmin(x1,x2)));
    int maxx=fmin(r->w-1,fmax(x0,fmax(x1,x2)));
    int miny=fmax(0,fmin(y0,fmin(y1,y2)));
    int maxy=fmin(r->h-1,fmax(y0,fmax(y1,y2)));
    float area=(x1-x0)*(y2-y0)-(x2-x0)*(y1-y0);
    if(area==0) return;
    for(int y=miny;y<=maxy;y++)
    for(int x=minx;x<=maxx;x++){
        float w0=(x1-x0)*(y-y0)-(y1-y0)*(x-x0);
        float w1=(x2-x1)*(y-y1)-(y2-y1)*(x-x1);
        float w2=(x0-x2)*(y-y2)-(y0-y2)*(x-x2);
        if((w0>=0&&w1>=0&&w2>=0)||(w0<=0&&w1<=0&&w2<=0)){
            float z=(a.z+b.z+c.z)/3.0f;
            r_putpixel(r,x,y,z,col);
        }
    }
}

/* ========================================================= */
/* Face Visibility                                           */
/* ========================================================= */
bool is_face_visible(int x,int y,int z,int face){
    static const int dir[6][3]={{0,0,1},{0,0,-1},{-1,0,0},{1,0,0},{0,1,0},{0,-1,0}};
    int nx=x+dir[face][0], ny=y+dir[face][1], nz=z+dir[face][2];
    if(nx<0||nx>=WORLD_SIZE||ny<0||ny>=WORLD_SIZE||nz<0||nz>=WORLD_SIZE)
        return true;
    BlockType n=world[nx][ny][nz];
    return n==BLOCK_AIR||block_types[n].transparent;
}

/* ========================================================= */
/* Face vertices                                             */
/* ========================================================= */
static const Vec3 face_vertices[6][4]={
    {{0,0,1},{1,0,1},{1,1,1},{0,1,1}}, // Front
    {{1,0,0},{0,0,0},{0,1,0},{1,1,0}}, // Back
    {{0,0,0},{0,0,1},{0,1,1},{0,1,0}}, // Left
    {{1,0,1},{1,0,0},{1,1,0},{1,1,1}}, // Right
    {{0,1,1},{1,1,1},{1,1,0},{0,1,0}}, // Top
    {{0,0,0},{1,0,0},{1,0,1},{0,0,1}}  // Bottom
};

/* ========================================================= */
/* Simple Quad mesh                                          */
/* ========================================================= */
typedef struct { Vec3 vertices[4]; BlockType type; int face; } SimpleQuad;
#define MAX_SIMPLE_QUADS 131072
SimpleQuad simple_quads[MAX_SIMPLE_QUADS];
int simple_quad_count=0;

void regenerate_mesh(){
    simple_quad_count=0;
    for(int x=0;x<WORLD_SIZE;x++)
    for(int y=0;y<WORLD_SIZE;y++)
    for(int z=0;z<WORLD_SIZE;z++){
        BlockType type=world[x][y][z];
        if(type==BLOCK_AIR) continue;
        for(int f=0;f<6;f++){
            if(is_face_visible(x,y,z,f)){
                if(simple_quad_count<MAX_SIMPLE_QUADS){
                    SimpleQuad*q=&simple_quads[simple_quad_count++];
                    q->type=type;q->face=f;
                    for(int i=0;i<4;i++){
                        q->vertices[i].x=x+face_vertices[f][i].x;
                        q->vertices[i].y=y+face_vertices[f][i].y;
                        q->vertices[i].z=z+face_vertices[f][i].z;
                    }
                }
            }
        }
    }
}

/* ========================================================= */
/* Unified Noise System                                      */
/* ========================================================= */

// Noise algorithm types
typedef enum {
    NOISE_VALUE = 0,
    NOISE_PERLIN,
    NOISE_SIMPLEX,
    NOISE_COUNT
} NoiseType;

// Current noise configuration
static NoiseType current_noise_type = NOISE_PERLIN;
static float noise_scale = 0.05f;
static int noise_octaves = 4;
static float noise_lacunarity = 2.0f;
static float noise_gain = 0.5f;
static float noise_persistence = 0.5f;

// Permutation table for Perlin/Simplex noise
static int p[512];
static unsigned int current_seed = 0;

// Helper function for Simplex noise (declared early)
static float dot2(int g, float x, float y){
    static const float grad2[12][2]={
        {1,1},{-1,1},{1,-1},{-1,-1},
        {1,0},{-1,0},{1,0},{-1,0},
        {0,1},{0,-1},{0,1},{0,-1}
    };
    return grad2[g][0]*x + grad2[g][1]*y;
}

// Initialize permutation table
static void init_permutation(unsigned int seed){
    if(seed == current_seed) return;

    current_seed = seed;

    // Create initial permutation
    int perm[256];
    for(int i=0;i<256;i++) perm[i]=i;

    // Seed the random number generator
    srand(seed);

    // Shuffle using Fisher-Yates
    for(int i=255;i>0;i--){
        int j=rand()%(i+1);
        int temp=perm[i];
        perm[i]=perm[j];
        perm[j]=temp;
    }

    // Duplicate for overflow
    for(int i=0;i<512;i++) p[i]=perm[i&255];
}

/* ========================================================= */
/* Value Noise                                               */
/* ========================================================= */
static inline float hash(int x,int z,unsigned int seed){
    unsigned int h=x*374761393u+z*668265263u+seed*982451653u;
    h=(h^(h>>13))*1274126177u;
    return (h & 0xFFFFFF)/ (float)0xFFFFFF;
}

static inline float lerp(float a,float b,float t){
    return a+t*(b-a);
}

static float value_noise_2d(float x,float z,unsigned int seed){
    int xi=(int)floorf(x), zi=(int)floorf(z);
    float xf=x-xi, zf=z-zi;
    float v00=hash(xi,zi,seed), v10=hash(xi+1,zi,seed),
          v01=hash(xi,zi+1,seed), v11=hash(xi+1,zi+1,seed);
    return lerp(lerp(v00,v10,xf), lerp(v01,v11,xf), zf);
}

/* ========================================================= */
/* Perlin Noise                                              */
/* ========================================================= */
static float fade(float t){
    return t * t * t * (t * (t * 6 - 15) + 10);
}

static float grad(int hash,float x,float y,float z){
    int h=hash&15;
    float u=h<8?x:y;
    float v=h<4?y:(h==12||h==14?x:z);
    return ((h&1)==0?u:-u)+((h&2)==0?v:-v);
}

static float perlin_3d(float x,float y,float z){
    init_permutation(WORLD_SEED);

    int X=(int)floorf(x)&255;
    int Y=(int)floorf(y)&255;
    int Z=(int)floorf(z)&255;

    x-=floorf(x);
    y-=floorf(y);
    z-=floorf(z);

    float u=fade(x);
    float v=fade(y);
    float w=fade(z);

    int A=p[X]+Y, AA=p[A]+Z, AB=p[A+1]+Z;
    int B=p[X+1]+Y, BA=p[B]+Z, BB=p[B+1]+Z;

    return lerp(
        lerp(
            lerp(grad(p[AA],x,y,z),grad(p[BA],x-1,y,z),u),
            lerp(grad(p[AB],x,y-1,z),grad(p[BB],x-1,y-1,z),u),
            v),
        lerp(
            lerp(grad(p[AA+1],x,y,z-1),grad(p[BA+1],x-1,y,z-1),u),
            lerp(grad(p[AB+1],x,y-1,z-1),grad(p[BB+1],x-1,y-1,z-1),u),
            v),
        w);
}

/* ========================================================= */
/* Simplex Noise (Simplified 2D)                            */
/* ========================================================= */
static float simplex_2d(float x, float y){
    init_permutation(WORLD_SEED);

    const float F2 = 0.5f*(sqrtf(3.0f)-1.0f);
    const float G2 = (3.0f-sqrtf(3.0f))/6.0f;

    float s = (x+y)*F2;
    int i = (int)floorf(x+s);
    int j = (int)floorf(y+s);

    float t = (i+j)*G2;
    float X0 = i-t;
    float Y0 = j-t;
    float x0 = x-X0;
    float y0 = y-Y0;

    int i1, j1;
    if(x0>y0){i1=1; j1=0;}
    else {i1=0; j1=1;}

    float x1 = x0 - i1 + G2;
    float y1 = y0 - j1 + G2;
    float x2 = x0 - 1.0f + 2.0f*G2;
    float y2 = y0 - 1.0f + 2.0f*G2;

    int ii = i & 255;
    int jj = j & 255;
    int gi0 = p[ii+p[jj]] % 12;
    int gi1 = p[ii+i1+p[jj+j1]] % 12;
    int gi2 = p[ii+1+p[jj+1]] % 12;

    float t0 = 0.5f - x0*x0 - y0*y0;
    float n0;
    if(t0<0) n0=0.0f;
    else{
        t0*=t0;
        n0=t0*t0*dot2(gi0,x0,y0);
    }

    float t1 = 0.5f - x1*x1 - y1*y1;
    float n1;
    if(t1<0) n1=0.0f;
    else{
        t1*=t1;
        n1=t1*t1*dot2(gi1,x1,y1);
    }

    float t2 = 0.5f - x2*x2 - y2*y2;
    float n2;
    if(t2<0) n2=0.0f;
    else{
        t2*=t2;
        n2=t2*t2*dot2(gi2,x2,y2);
    }

    return 70.0f*(n0+n1+n2);
}

/* ========================================================= */
/* Unified Noise Function                                    */
/* ========================================================= */
static float noise_2d(float x, float y){
    switch(current_noise_type){
        case NOISE_VALUE:
            return value_noise_2d(x, y, WORLD_SEED) * 2.0f - 1.0f;

        case NOISE_PERLIN:
            return perlin_3d(x, y, 0.0f);

        case NOISE_SIMPLEX:
            return simplex_2d(x, y) / 70.0f; // Normalize

        default:
            return perlin_3d(x, y, 0.0f);
    }
}

static float noise_3d(float x, float y, float z){
    switch(current_noise_type){
        case NOISE_VALUE:
            // Value noise doesn't have good 3D, use 2D with z as extra seed
            return value_noise_2d(x + z * 0.5f, y + z * 0.5f, WORLD_SEED + (int)z) * 2.0f - 1.0f;

        case NOISE_PERLIN:
            return perlin_3d(x, y, z);

        case NOISE_SIMPLEX:
            // Simplex simplified to 2D for now
            return simplex_2d(x + z * 0.3f, y + z * 0.3f) / 70.0f;

        default:
            return perlin_3d(x, y, z);
    }
}

// Fractal Brownian Motion (with all noise types)
static float fbm_2d(float x, float y){
    float total = 0.0f;
    float frequency = 1.0f;
    float amplitude = 1.0f;
    float max_value = 0.0f;

    for(int i=0; i<noise_octaves; i++){
        total += noise_2d(x * frequency, y * frequency) * amplitude;
        max_value += amplitude;
        amplitude *= noise_gain;
        frequency *= noise_lacunarity;
    }

    if(max_value > 0.0f){
        return total / max_value;
    }
    return total;
}

static float fbm_3d(float x, float y, float z){
    float total = 0.0f;
    float frequency = 1.0f;
    float amplitude = 1.0f;
    float max_value = 0.0f;

    for(int i=0; i<noise_octaves; i++){
        total += noise_3d(x * frequency, y * frequency, z * frequency) * amplitude;
        max_value += amplitude;
        amplitude *= noise_gain;
        frequency *= noise_lacunarity;
    }

    if(max_value > 0.0f){
        return total / max_value;
    }
    return total;
}

/* ========================================================= */
/* World generation with configurable noise                  */
/* ========================================================= */
void generate_world(){
    memset(world, BLOCK_AIR, sizeof(world));
    const int SEA_LEVEL = 8;
    const int BASE_HEIGHT = 10;

    // Force reinitialization of permutation table with new seed
    if(current_noise_type == NOISE_PERLIN || current_noise_type == NOISE_SIMPLEX){
        init_permutation(WORLD_SEED);
    }

    for(int x=0; x<WORLD_SIZE; x++){
        for(int z=0; z<WORLD_SIZE; z++){
            // Convert to normalized coordinates
            float nx = (float)x * noise_scale;
            float nz = (float)z * noise_scale;

            // Generate height using FBM
            float noise_value = fbm_2d(nx, nz);

            // Convert from [-1,1] to [0,1]
            noise_value = (noise_value + 1.0f) * 0.5f;

            // Calculate terrain height
            int h = BASE_HEIGHT + (int)(noise_value * 20.0f);

            // Clamp height
            if(h < 1) h = 1;
            if(h >= WORLD_SIZE-1) h = WORLD_SIZE-2;

            // Generate 3D noise for caves/overhangs
            for(int y=0; y<h; y++){
                float ny = (float)y * noise_scale * 0.5f;
                float cave_noise = fbm_3d(nx, ny, nz);
                cave_noise = (cave_noise + 1.0f) * 0.5f;

                // Only place blocks where 3D noise is above threshold
                if(cave_noise > 0.3f){
                    if(y == h-1){
                        // Top layer
                        if(h <= SEA_LEVEL+2){
                            world[x][y][z] = BLOCK_SAND;
                        } else {
                            world[x][y][z] = BLOCK_GRASS;
                        }
                    } else if(y >= h-4) {
                        // Upper layers
                        world[x][y][z] = BLOCK_DIRT;
                    } else {
                        // Deep layers - mostly stone
                        world[x][y][z] = BLOCK_STONE;
                    }
                }
            }

            // Add water up to sea level
            for(int y=h; y<=SEA_LEVEL; y++){
                if(y < WORLD_SIZE){
                    if(world[x][y][z] == BLOCK_AIR){
                        world[x][y][z] = BLOCK_WATER;
                    }
                }
            }

            // Add trees
            if(h > SEA_LEVEL+3){
                float tree_noise = fbm_2d(nx*3.0f, nz*3.0f);
                tree_noise = (tree_noise + 1.0f) * 0.5f;

                if(tree_noise > 0.8f && h+6 < WORLD_SIZE){
                    // Trunk
                    for(int i=0; i<5; i++){
                        if(h+i < WORLD_SIZE){
                            world[x][h+i][z] = BLOCK_WOOD;
                        }
                    }

                    // Simple leaf canopy
                    int leaf_radius = 2;
                    for(int dx=-leaf_radius; dx<=leaf_radius; dx++){
                        for(int dz=-leaf_radius; dz<=leaf_radius; dz++){
                            for(int dy=2; dy<=4; dy++){
                                if(abs(dx)+abs(dz)+abs(dy-3) < 4){
                                    int wx = x+dx;
                                    int wy = h+dy;
                                    int wz = z+dz;

                                    if(wx>=0 && wx<WORLD_SIZE &&
                                       wy>=0 && wy<WORLD_SIZE &&
                                       wz>=0 && wz<WORLD_SIZE){
                                        if(world[wx][wy][wz] == BLOCK_AIR){
                                            world[wx][wy][wz] = BLOCK_LEAVES;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Add some structures
    srand(WORLD_SEED);
    for(int i=0; i<3; i++){
        int sx = rand() % (WORLD_SIZE-10) + 5;
        int sz = rand() % (WORLD_SIZE-10) + 5;
        int sy = 0;

        // Find ground level
        for(sy=0; sy<WORLD_SIZE-1; sy++){
            if(world[sx][sy][sz] != BLOCK_AIR &&
               world[sx][sy][sz] != BLOCK_WATER){
                break;
            }
        }

        if(sy < WORLD_SIZE-5){
            // Create a simple structure
            int structure_type = rand() % 3;
            if(structure_type == 0){
                // Glass tower
                for(int y=sy+1; y<sy+5; y++){
                    if(y < WORLD_SIZE){
                        world[sx][y][sz] = BLOCK_GLASS;
                    }
                }
            } else if(structure_type == 1){
                // Brick column
                for(int y=sy+1; y<sy+4; y++){
                    if(y < WORLD_SIZE){
                        world[sx][y][sz] = BLOCK_BRICK;
                    }
                }
            }
        }
    }
}

/* ========================================================= */
/* Render quad                                               */
/* ========================================================= */
void render_simple_quad(Renderer* r, SimpleQuad* q, Vec3 cam, float yaw, float pitch, float fov){
    BlockData* block=&block_types[q->type];
    Uint32 color=(q->face==4)?block->top_color:
                 (q->face==5)?block->bottom_color:block->side_color;
    if(block->transparent && !r->wireframe && !r->show_occluded) return;

    Vec3 v[4];
    for(int i=0;i<4;i++){
        // Translate
        v[i]=(Vec3){q->vertices[i].x-cam.x, q->vertices[i].y-cam.y, q->vertices[i].z-cam.z};

        // Rotate yaw
        float x1=v[i].x*cosf(yaw)-v[i].z*sinf(yaw);
        float z1=v[i].x*sinf(yaw)+v[i].z*cosf(yaw);
        // Rotate pitch
        float y1=v[i].y*cosf(pitch)-z1*sinf(pitch);
        float z2=v[i].y*sinf(pitch)+z1*cosf(pitch);
        v[i]=(Vec3){x1,y1,z2};
    }

    float f=fov*tanf(FOV*0.5f*M_PI/180.0f);
    r_triangle(r,v[0],v[1],v[2],color,f);
    r_triangle(r,v[0],v[2],v[3],color,f);
}

/* ========================================================= */
/* Draw world                                                */
/* ========================================================= */
void draw_chunk_borders(Renderer* r, Vec3 cam, float yaw, float pitch, float fov){
    Uint32 chunk_color = 0xFFFF0000; // Red color for chunk borders

    for(int cx=0;cx<WORLD_CHUNKS;cx++){
        for(int cy=0;cy<WORLD_CHUNKS;cy++){
            for(int cz=0;cz<WORLD_CHUNKS;cz++){
                // Calculate chunk position in world coordinates
                float chunk_x = cx * CHUNK_SIZE;
                float chunk_y = cy * CHUNK_SIZE;
                float chunk_z = cz * CHUNK_SIZE;

                // Define the 8 corners of the chunk
                Vec3 corners[8] = {
                    {chunk_x, chunk_y, chunk_z},
                    {chunk_x + CHUNK_SIZE, chunk_y, chunk_z},
                    {chunk_x, chunk_y + CHUNK_SIZE, chunk_z},
                    {chunk_x + CHUNK_SIZE, chunk_y + CHUNK_SIZE, chunk_z},
                    {chunk_x, chunk_y, chunk_z + CHUNK_SIZE},
                    {chunk_x + CHUNK_SIZE, chunk_y, chunk_z + CHUNK_SIZE},
                    {chunk_x, chunk_y + CHUNK_SIZE, chunk_z + CHUNK_SIZE},
                    {chunk_x + CHUNK_SIZE, chunk_y + CHUNK_SIZE, chunk_z + CHUNK_SIZE}
                };

                // Define the 12 edges of the chunk cube
                int edges[12][2] = {
                    {0,1}, {1,3}, {3,2}, {2,0}, // Bottom square
                    {4,5}, {5,7}, {7,6}, {6,4}, // Top square
                    {0,4}, {1,5}, {2,6}, {3,7}  // Vertical edges
                };

                // Draw each edge as a line
                for(int e=0;e<12;e++){
                    Vec3 start = corners[edges[e][0]];
                    Vec3 end = corners[edges[e][1]];

                    // Transform to camera space
                    Vec3 v_start = {start.x - cam.x, start.y - cam.y, start.z - cam.z};
                    Vec3 v_end = {end.x - cam.x, end.y - cam.y, end.z - cam.z};

                    // Rotate yaw
                    float x1 = v_start.x*cosf(yaw) - v_start.z*sinf(yaw);
                    float z1 = v_start.x*sinf(yaw) + v_start.z*cosf(yaw);
                    float x2 = v_end.x*cosf(yaw) - v_end.z*sinf(yaw);
                    float z2 = v_end.x*sinf(yaw) + v_end.z*cosf(yaw);

                    // Rotate pitch
                    float y1 = v_start.y*cosf(pitch) - z1*sinf(pitch);
                    float z1_final = v_start.y*sinf(pitch) + z1*cosf(pitch);
                    float y2 = v_end.y*cosf(pitch) - z2*sinf(pitch);
                    float z2_final = v_end.y*sinf(pitch) + z2*cosf(pitch);

                    // Check if both points are behind camera
                    if(z1_final <= NEARZ && z2_final <= NEARZ) continue;

                    // Project to screen
                    float f = fov*tanf(FOV*0.5f*M_PI/180.0f);
                    int sx1 = (int)((x1/z1_final)*f + r->w*0.5f);
                    int sy1 = (int)((-y1/z1_final)*f + r->h*0.5f);
                    int sx2 = (int)((x2/z2_final)*f + r->w*0.5f);
                    int sy2 = (int)((-y2/z2_final)*f + r->h*0.5f);

                    // Draw the line
                    r_line(r, sx1, sy1, z1_final, sx2, sy2, z2_final, chunk_color);
                }
            }
        }
    }
}

/* ========================================================= */
/* Draw origin marker (0,0,0)                                */
/* ========================================================= */
void draw_origin_marker(Renderer* r, Vec3 cam, float yaw, float pitch, float fov){
    Uint32 origin_color = 0xFF00FFFF; // Cyan color for origin marker

    // Create a 3D cross at the origin
    // X axis (red)
    Vec3 x_start = {-1.0f, 0.0f, 0.0f};
    Vec3 x_end = {1.0f, 0.0f, 0.0f};

    // Y axis (green)
    Vec3 y_start = {0.0f, -1.0f, 0.0f};
    Vec3 y_end = {0.0f, 1.0f, 0.0f};

    // Z axis (blue)
    Vec3 z_start = {0.0f, 0.0f, -1.0f};
    Vec3 z_end = {0.0f, 0.0f, 1.0f};

    // Center sphere (cyan)
    Vec3 center = {0.0f, 0.0f, 0.0f};
    float sphere_radius = 0.5f;

    // Draw the 3 axes
    Vec3 axes[6] = {x_start, x_end, y_start, y_end, z_start, z_end};
    Uint32 axis_colors[3] = {0xFFFF0000, 0xFF00FF00, 0xFF0000FF}; // Red, Green, Blue

    for(int axis = 0; axis < 3; axis++){
        Vec3 start = axes[axis*2];
        Vec3 end = axes[axis*2 + 1];

        // Transform to camera space
        Vec3 v_start = {start.x - cam.x, start.y - cam.y, start.z - cam.z};
        Vec3 v_end = {end.x - cam.x, end.y - cam.y, end.z - cam.z};

        // Rotate yaw
        float x1 = v_start.x*cosf(yaw) - v_start.z*sinf(yaw);
        float z1 = v_start.x*sinf(yaw) + v_start.z*cosf(yaw);
        float x2 = v_end.x*cosf(yaw) - v_end.z*sinf(yaw);
        float z2 = v_end.x*sinf(yaw) + v_end.z*cosf(yaw);

        // Rotate pitch
        float y1 = v_start.y*cosf(pitch) - z1*sinf(pitch);
        float z1_final = v_start.y*sinf(pitch) + z1*cosf(pitch);
        float y2 = v_end.y*cosf(pitch) - z2*sinf(pitch);
        float z2_final = v_end.y*sinf(pitch) + z2*cosf(pitch);

        // Check if both points are behind camera
        if(z1_final <= NEARZ && z2_final <= NEARZ) continue;

        // Project to screen
        float f = fov*tanf(FOV*0.5f*M_PI/180.0f);
        int sx1 = (int)((x1/z1_final)*f + r->w*0.5f);
        int sy1 = (int)((-y1/z1_final)*f + r->h*0.5f);
        int sx2 = (int)((x2/z2_final)*f + r->w*0.5f);
        int sy2 = (int)((-y2/z2_final)*f + r->h*0.5f);

        // Draw the axis line
        r_line(r, sx1, sy1, z1_final, sx2, sy2, z2_final, axis_colors[axis]);
    }

    // Draw a small sphere at the origin
    // Create a simple wireframe cube around the origin
    float size = sphere_radius;
    Vec3 cube_corners[8] = {
        {-size, -size, -size},
        {size, -size, -size},
        {-size, size, -size},
        {size, size, -size},
        {-size, -size, size},
        {size, -size, size},
        {-size, size, size},
        {size, size, size}
    };

    int cube_edges[12][2] = {
        {0,1}, {1,3}, {3,2}, {2,0}, // Front face
        {4,5}, {5,7}, {7,6}, {6,4}, // Back face
        {0,4}, {1,5}, {2,6}, {3,7}  // Connecting edges
    };

    for(int e=0;e<12;e++){
        Vec3 start = cube_corners[cube_edges[e][0]];
        Vec3 end = cube_corners[cube_edges[e][1]];

        // Transform to camera space
        Vec3 v_start = {start.x - cam.x, start.y - cam.y, start.z - cam.z};
        Vec3 v_end = {end.x - cam.x, end.y - cam.y, end.z - cam.z};

        // Rotate yaw
        float x1 = v_start.x*cosf(yaw) - v_start.z*sinf(yaw);
        float z1 = v_start.x*sinf(yaw) + v_start.z*cosf(yaw);
        float x2 = v_end.x*cosf(yaw) - v_end.z*sinf(yaw);
        float z2 = v_end.x*sinf(yaw) + v_end.z*cosf(yaw);

        // Rotate pitch
        float y1 = v_start.y*cosf(pitch) - z1*sinf(pitch);
        float z1_final = v_start.y*sinf(pitch) + z1*cosf(pitch);
        float y2 = v_end.y*cosf(pitch) - z2*sinf(pitch);
        float z2_final = v_end.y*sinf(pitch) + z2*cosf(pitch);

        // Check if both points are behind camera
        if(z1_final <= NEARZ && z2_final <= NEARZ) continue;

        // Project to screen
        float f = fov*tanf(FOV*0.5f*M_PI/180.0f);
        int sx1 = (int)((x1/z1_final)*f + r->w*0.5f);
        int sy1 = (int)((-y1/z1_final)*f + r->h*0.5f);
        int sx2 = (int)((x2/z2_final)*f + r->w*0.5f);
        int sy2 = (int)((-y2/z2_final)*f + r->h*0.5f);

        // Draw the cube edge
        r_line(r, sx1, sy1, z1_final, sx2, sy2, z2_final, origin_color);
    }
}

void draw_world(Renderer* r, Vec3 cam, float yaw, float pitch, float fov){
    // Draw all quads
    for(int i=0;i<simple_quad_count;i++)
        render_simple_quad(r,&simple_quads[i],cam,yaw,pitch,fov);

    // Draw chunk borders if enabled
    if(r->show_chunks)
        draw_chunk_borders(r,cam,yaw,pitch,fov);

    // Draw origin marker (always visible)
    draw_origin_marker(r,cam,yaw,pitch,fov);
}

/* ========================================================= */
/* HUD                                                       */
/* ========================================================= */
bool hud=true,background=true;
float starting_camera_distance = 30.0f; // 30 cubes
bool invert_x = false;
bool invert_y = false;
float mouse_x_rel = 0.0f;
float mouse_y_rel = 0.0f;

void draw_hud(Renderer* r, Vec3 cam, bool mouse_captured, float yaw, float pitch){
    int hw=450, hh=400;
    // Draw border
    for(int x=10;x<hw;x++){ r_putpixel_hud(r,x,10,0xFFFFFFFF); r_putpixel_hud(r,x,hh-1,0xFFFFFFFF);}
    for(int y=10;y<hh;y++){ r_putpixel_hud(r,10,y,0xFFFFFFFF); r_putpixel_hud(r,hw-1,y,0xFFFFFFFF);}

    char buf[128];
    int x=18,y=18;

    snprintf(buf,sizeof(buf),"Camera X: %.2f Y: %.2f Z: %.2f",cam.x,cam.y,cam.z);
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Yaw: %.2f Pitch: %.2f",yaw,pitch);
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Starting distance: %.2f cubes",starting_camera_distance);
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Mouse captured: %s",mouse_captured?"Yes":"No");
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Quads: %d",simple_quad_count);
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Chunk borders: %s",r->show_chunks?"ON":"OFF");
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"World size: %dx%dx%d",WORLD_SIZE,WORLD_SIZE,WORLD_SIZE);
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Chunks: %dx%dx%d (%d cubes each)",
             WORLD_CHUNKS,WORLD_CHUNKS,WORLD_CHUNKS,CHUNK_SIZE);
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Invert X: %s",invert_x?"ON":"OFF");
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Invert Y: %s",invert_y?"ON":"OFF");
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Mouse X: %.1f Y: %.1f",mouse_x_rel,mouse_y_rel);
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    // Noise settings section
    r_text(r,x,y,"=== NOISE SETTINGS ===",0xFFFFFF00); y+=12;

    const char* noise_names[] = {"Value", "Perlin", "Simplex"};
    snprintf(buf,sizeof(buf),"Type: %s (1/2/3)", noise_names[current_noise_type]);
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Seed: %u",WORLD_SEED);
    r_text(r,x,y,buf,0xFFFFFF00); y+=12;

    snprintf(buf,sizeof(buf),"Scale: %.3f ([/])", noise_scale);
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Octaves: %d (O/P)", noise_octaves);
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Lacunarity: %.2f (L/K)", noise_lacunarity);
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    snprintf(buf,sizeof(buf),"Gain: %.2f (H/J)", noise_gain);
    r_text(r,x,y,buf,0xFFFFFFFF); y+=12;

    // Controls
    r_text(r,x,y,"=== CONTROLS ===",0xFFFFFF00); y+=12;
    r_text(r,x,y,"W/A/S/D - Move",0xFFFFFFFF); y+=12;
    r_text(r,x,y,"Space - Up, Shift - Down",0xFFFFFFFF); y+=12;
    r_text(r,x,y,"TAB - Toggle mouse capture",0xFFFFFFFF); y+=12;
    r_text(r,x,y,"ESC - Quit",0xFFFFFFFF); y+=12;
    r_text(r,x,y,"` - Toggle HUD",0xFFFFFFFF); y+=12;
    r_text(r,x,y,"F - Toggle Wireframe",0xFFFFFFFF); y+=12;
    r_text(r,x,y,"C - Toggle Chunk view",0xFFFFFFFF); y+=12;
    r_text(r,x,y,"R - Reset camera",0xFFFFFFFF); y+=12;
    r_text(r,x,y,"G - Regenerate world",0xFFFFFFFF); y+=12;
    r_text(r,x,y,"X/Y - Invert mouse axes",0xFFFFFFFF); y+=12;
    r_text(r,x,y,"1/2/3 - Noise type",0xFFFFFF00); y+=12;
    r_text(r,x,y,"9/0 - Scale, O/P - Octaves",0xFFFFFF00); y+=12;
    r_text(r,x,y,"L/K - Lacunarity, H/J - Gain",0xFFFFFF00); y+=12;
}

/* ========================================================= */
/* Main                                                     */
/* ========================================================= */
int main(int argc,char** argv){
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window* win=SDL_CreateWindow("Voxel engine - pre-templeOS",SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,WIDTH,HEIGHT,0);
    SDL_Renderer* sdlr=SDL_CreateRenderer(win,-1,SDL_RENDERER_ACCELERATED);
    SDL_Texture* tex=SDL_CreateTexture(sdlr,SDL_PIXELFORMAT_ARGB8888,SDL_TEXTUREACCESS_STREAMING,WIDTH,HEIGHT);

    Renderer r={WIDTH,HEIGHT};
    r.color=malloc(sizeof(Uint32)*WIDTH*HEIGHT);
    r.depth=malloc(sizeof(float)*WIDTH*HEIGHT);
    r.wireframe=false;
    r.show_chunks=true;
    r.show_occluded=false;

    generate_world();
    regenerate_mesh();

    // Start camera position - looking at the center of the world from the front
    // World is 64x64x64, so center is at 32,32,32
    // We want to start 30 units in front (negative Z) looking at the world
    Vec3 cam={
        WORLD_SIZE/2.0f,
        WORLD_SIZE/2.0f + 10.0f,  // Start a bit higher to see more of the terrain
        -starting_camera_distance  // Negative Z means in front of the world
    };
    float yaw=0.0f, pitch=-0.2f;  // Slight pitch down to look at the world

    bool mouse_captured=false;

    Uint32 last=SDL_GetTicks();
    bool quit=false;
    while(!quit){
        Uint32 now=SDL_GetTicks();
        float dt=(now-last)/1000.0f;
        last=now;

        // Reset mouse relative values for this frame
        mouse_x_rel = 0.0f;
        mouse_y_rel = 0.0f;

        SDL_Event ev;
        while(SDL_PollEvent(&ev)){
            if(ev.type==SDL_QUIT) quit=true;
            if(ev.type==SDL_KEYDOWN){
                bool regenerate = false;

                switch(ev.key.keysym.sym){
                    case SDLK_ESCAPE: quit = true; break;
                    case SDLK_BACKQUOTE: hud = !hud; break;
                    case SDLK_b: background = !background; break;
                    case SDLK_f: r.wireframe = !r.wireframe; break;
                    case SDLK_c: r.show_chunks = !r.show_chunks; break; // 'c' for chunk borders only
                    case SDLK_g:
                        WORLD_SEED = rand();
                        regenerate = true;
                        break;
                    case SDLK_TAB:
                        mouse_captured = !mouse_captured;
                        SDL_SetRelativeMouseMode(mouse_captured ? SDL_TRUE : SDL_FALSE);
                        SDL_ShowCursor(mouse_captured ? SDL_DISABLE : SDL_ENABLE);
                        break;
                    case SDLK_r: // Reset camera
                        cam=(Vec3){
                            WORLD_SIZE/2.0f,
                            WORLD_SIZE/2.0f + 10.0f,
                            -starting_camera_distance  // In front of world
                        };
                        yaw = 0.0f;
                        pitch = -0.2f;
                        break;
                    case SDLK_x: // Toggle invert X
                        invert_x = !invert_x;
                        break;
                    case SDLK_y: // Toggle invert Y
                        invert_y = !invert_y;
                        break;

                    // Noise type selection
                    case SDLK_1:
                        current_noise_type = NOISE_VALUE;
                        regenerate = true;
                        break;
                    case SDLK_2:
                        current_noise_type = NOISE_PERLIN;
                        regenerate = true;
                        break;
                    case SDLK_3:
                        current_noise_type = NOISE_SIMPLEX;
                        regenerate = true;
                        break;

                    // Noise parameter adjustments
                    case SDLK_LEFTBRACKET: // Decrease scale
                        noise_scale = fmaxf(0.01f, noise_scale - 0.005f);
                        regenerate = true;
                        break;
                    case SDLK_RIGHTBRACKET: // Increase scale
                        noise_scale = fminf(0.5f, noise_scale + 0.005f);
                        regenerate = true;
                        break;
                    case SDLK_o: // Decrease octaves
                        noise_octaves = fmax(1, noise_octaves - 1);
                        regenerate = true;
                        break;
                    case SDLK_p: // Increase octaves
                        noise_octaves = fmin(8, noise_octaves + 1);
                        regenerate = true;
                        break;
                    case SDLK_l: // Decrease lacunarity (changed from Z to L)
                        noise_lacunarity = fmaxf(1.1f, noise_lacunarity - 0.1f);
                        regenerate = true;
                        break;
                    case SDLK_k: // Increase lacunarity (changed from L to K)
                        noise_lacunarity = fminf(4.0f, noise_lacunarity + 0.1f);
                        regenerate = true;
                        break;
                    case SDLK_j: // Decrease gain
                        noise_gain = fmaxf(0.1f, noise_gain - 0.05f);
                        regenerate = true;
                        break;
                    case SDLK_h: // Increase gain
                        noise_gain = fminf(1.0f, noise_gain + 0.05f);
                        regenerate = true;
                        break;
                }

                if(regenerate){
                    generate_world();
                    regenerate_mesh();
                }
            }
            if(ev.type==SDL_MOUSEMOTION && mouse_captured){
                float xrel = (float)ev.motion.xrel;
                float yrel = (float)ev.motion.yrel;

                // Store for debugging
                mouse_x_rel = xrel;
                mouse_y_rel = yrel;

                // Apply inversion if enabled
                if(invert_x) xrel = -xrel;
                if(invert_y) yrel = -yrel;

                yaw   += xrel * SENS;
                pitch += yrel * SENS;

                if(pitch>1.5f) pitch=1.5f;
                if(pitch<-1.5f) pitch=-1.5f;
            }
        }

        const Uint8* keys=SDL_GetKeyboardState(NULL);
        Vec3 dir={0,0,0};
        if(keys[SDL_SCANCODE_W]) dir.z-=1;
        if(keys[SDL_SCANCODE_S]) dir.z+=1;
        if(keys[SDL_SCANCODE_A]) dir.x-=1;
        if(keys[SDL_SCANCODE_D]) dir.x+=1;
        if(keys[SDL_SCANCODE_SPACE]) dir.y+=1;
        if(keys[SDL_SCANCODE_LSHIFT]) dir.y-=1;

        float cs=cosf(yaw), sn=sinf(yaw);
        cam.x+=dt*SPEED*(dir.x*cs - dir.z*sn);
        cam.z+=dt*SPEED*(dir.x*sn + dir.z*cs);
        cam.y+=dt*SPEED*dir.y;

        float height_factor=fminf(1.0f,fmaxf(0.0f,cam.y/50.0f));
        int sky_r=40+(int)(100*(1.0f-height_factor));
        int sky_g=50+(int)(150*(1.0f-height_factor));
        int sky_b=58+(int)(197*(1.0f-height_factor));
        Uint32 bg_color = background?((sky_r<<24)|(sky_g<<16)|(sky_b<<8)|0xFF):0x00;
        r_clear(&r,bg_color);

        draw_world(&r,cam,yaw,pitch,WIDTH*0.5f);

        if(hud) draw_hud(&r,cam,mouse_captured,yaw,pitch);

        SDL_UpdateTexture(tex,NULL,r.color,WIDTH*sizeof(Uint32));
        SDL_RenderClear(sdlr);
        SDL_RenderCopy(sdlr,tex,NULL,NULL);
        SDL_RenderPresent(sdlr);
    }

    free(r.color);
    free(r.depth);
    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(sdlr);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}