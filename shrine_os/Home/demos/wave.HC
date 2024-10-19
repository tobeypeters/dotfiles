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

/*wave.HC
  Description:
      2d Terrain generator using the wave collapse algorithm.
*/

#define WIDTH 40
#define HEIGHT 30

// Terrain types
#define WATER 0
#define GRASS 1
#define HILL 2
#define MOUNTAIN 3
#define TERRAINCNT 4

// Adjacency rules
I64 rules[TERRAINCNT][TERRAINCNT] = {
    // WATER, GRASS, HILL, MOUNTAIN
    { 1, 1, 0, 0 },  // WATER can connect to WATER, GRASS
    { 1, 1, 1, 0 },  // GRASS can connect to WATER, GRASS, HILL
    { 0, 1, 1, 1 },  // HILL can connect to GRASS, HILL, MOUNTAIN
    { 0, 0, 1, 1 }   // MOUNTAIN can connect to HILL, MOUNTAIN
};

// Terrain representation (the final map)
I64 terrain[HEIGHT][WIDTH];

// Function to print the terrain
U0 printTerrain() {
  I64 x,y;
  for (y=0;y<HEIGHT;y++) {
    for (x=0;x<WIDTH;x++) {
      switch (terrain[y][x]) {
        start:
          case WATER: "$$LTCYAN$$"; break;
          case GRASS: "$$GREEN$$"; break;
          case HILL: "$$BROWN$$"; break;
          case MOUNTAIN: "$$WHITE$$"; break;
        end:
          "±$$FG$$";
          break;
      }
    }
    "\n";
  }
}

// Function to check if two tiles can be adjacent based on the rules
I64 canPlace(I64 current,I64 neighbor) return rules[current][neighbor];

// Function to randomly choose a valid tile based on its neighbors
I64 chooseTile(I64 x,I64 y) {
  // Assume all tiles are possible initially
  I64 options[TERRAINCNT],i;
  for (i=0;i<TERRAINCNT;i++) options[i]=1;

  // Check the tile to the left
  if (x > 0) {
    I64 left=terrain[y][x-1];
    for (i=0;i<4;i++) {
      if (!canPlace(left,i)) options[i]=0;
    }
  }

  // Check the tile above
  if (y > 0) {
    I64 above=terrain[y-1][x];
    for (i=0;i<4;i++) {
      if (!canPlace(above, i)) options[i]=0;
    }
  }

  // Choose a random valid option
  I64 validOptions[4];
  I64 count=0;
  for (i=0;i<4;i++) {
    if (options[i]) {
      validOptions[count++]=i;
    }
  }
  if (count==0) return GRASS;  // Fallback, should not happen if rules are consistent

  // Return a random valid tile
  return validOptions[RandU16%count];
}

// Function to generate the terrain using WFC
U0 generateTerrain() {
  I64 x,y;

  // Initialize terrain to an undefined state (-1)
  for (y=0;y<HEIGHT;y++) {
    for (x=0;x<WIDTH;x++) {
      terrain[y][x]=-1; // Undefined state
    }
  }

  // Start by collapsing the first tile
  terrain[0][0]=RandU16%4;

  // Loop over each cell and collapse the wave
  for (y=0;y<HEIGHT;y++) {
    for (x=0;x<WIDTH;x++) {
      if (terrain[y][x]==-1) {
        terrain[y][x]=chooseTile(x,y);
      }
    }
  }
}

generateTerrain();
printTerrain();
