#define WIDTH 40   // Number of horizontal sections (640 / 16)
#define HEIGHT 30  // Number of vertical sections (480 / 16)
#define RAND_RANGE 1.0  // Initial random range for terrain values

F64 terrain[WIDTH][HEIGHT];

// Function to generate a random float between -range and +range
F64 rand_float(F64 range=RAND_RANGE){
 F64 test=Rand/I16_MAX*2*range-range;
 "%n\n",test;
 return test;
// return Rand/I16_MAX*2*range-range;
}

MemSet(terrain,0,sizeof(terrain));
terrain[0][0]=rand_float;
terrain[0][HEIGHT-1]=rand_float;
terrain[WIDTH-1][0]=rand_float;
terrain[WIDTH-1][HEIGHT-1]=rand_float;

// Diamond step
U0 diamond_step(I64 x,U64 y,I64 size,F64 off) {
  I64 half=size/2;
  if (half<1) return;

  F64 avg=(terrain[x][y]+
           terrain[x+size][y]+
           terrain[x][y+size]+
           terrain[x+size][y+size])/4.0;

  terrain[x+half][y+half]=avg+rand_float(off);
}
// Square step
U0 square_step(I64 x,I64 y,I64 size,F64 off) {
  I64 half=size/2;

  F64 avg;

  // Top
  if (y-half>=0) {
    avg=(terrain[x][y-half]+
         terrain[x][y+half]+
         terrain[x-half][y]+
         terrain[x+half][y])/4.0;
    terrain[x][y]=avg+rand_float(off);
  }

  // Bottom
  if (y+size<HEIGHT) {
    avg=(terrain[x][y+size-half]+
         terrain[x+size-half][y+size-half]+
         terrain[x][y+size]+
         terrain[x+size-half][y+size])/4.0;
    terrain[x + half][y] = avg + rand_float(off);
  }
}
// Diamond-Square Algorithm
U0 diamond_square(I64 step_size,F64 roughness) {
  I64 half_step=step_size/2;
  if (half_step<1) return;

  I64 x,y;

  for (x=0;x<WIDTH-1;x+=step_size) {
    for (y=0;y<HEIGHT-1;y+=step_size) {
      diamond_step(x,y,step_size,roughness);
    }
  }

  for (x=0;x<WIDTH;x+=half_step) {
    for (y=(x+half_step)%step_size;y<HEIGHT;y+=step_size) {
      square_step(x,y,step_size,roughness);
    }
  }

  // Reduce roughness and repeat the process with smaller steps
  diamond_square(half_step,roughness/2);
}
// Display the terrain
U0 print_terrain() {
  I64 i,j;
  for (i=0;i<WIDTH;i++) {
    for (j=0;j<HEIGHT;j++) {
      "%5.2n ",terrain[i][j];
    }
    "\n";
  }
}

// Perform the Diamond-Square algorithm with initial step size and roughness
diamond_square(WIDTH-1,RAND_RANGE);

// Print the result (or display it on your 640x480 screen)
//print_terrain;

