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

/*voronoi.HC
  Description:
      Generates a voronoi diagram.
*/
Cd(__DIR__);;

#define SEEDS 20
#define PARTICLE_MAX SEEDS*2

#include "grdefs"

F64 prev_time,
   delta_time;

U0 DrawIt(CTask *task,CDC *dc)
{
  //DCFill(dc,BLACK);
  //p_plot(dc,&p_arr,PARTICLE_MAX);
  /*for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];
  }*/

/*
    for (size_t i = 0; i < SEEDS_COUNT; ++i) {
        float x = seed_positions[i].x + seed_velocities[i].x*delta_time;
        if (0 <= x && x <= DEFAULT_SCREEN_WIDTH) {
            seed_positions[i].x = x;
        } else {
            seed_velocities[i].x *= -1;
        }
        float y = seed_positions[i].y + seed_velocities[i].y*delta_time;
        if (0 <= y && y <= DEFAULT_SCREEN_HEIGHT) {
            seed_positions[i].y = y;
        } else {
            seed_velocities[i].y *= -1;
        }
    }
*/

}

F64 cur_time;
U0 AnimateTask(I64)
{
  while (TRUE) {
    cur_time=tS;
    delta_time=cur_time-prev_time;
    prev_time=cur_time;

    Sleep(20);
  }
}

F64 RandF64() {
  return Rand/F64_MAX;
}
U0 Init()
{
  F64 angle,mag;

  prev_time=delta_time=0;

  for (ita=0;ita<PARTICLE_MAX;ita++)
  {
    pp=&p_arr[ita];
    ppp=&p_arr[SEEDS+ita];

    pp->x= RandF64*WIDTH;
    pp->y = RandF64*HEIGHT;
    ppp->color.u8[0] = RandF64;
    ppp->color.u8[1] = RandF64;
    ppp->color.u8[2] = RandF64;
    ppp->color.u8[3] = 1;

    angle=RandF64*2*M_PI;
    mag=lerp(100,200,RandF64);
    pp->x=Cos(angle)*mag;
    pp->y=Sin(angle)*mag;
  }
}

U0 MS_L_DOWN(){}
U0 MS_L_UP(){}
U0 MS_MOVE(){}
U0 MS_MOVE_LDOWN(){}
U0 MS_MOVE_RDOWN(){}
U0 MS_R_DOWN(){}
U0 MS_R_UP(){}
U0 KEY_DOWN(){}

#define ANIMATE_TASK FALSE

#define MOUSE_TRAP FALSE

//Update mouse postion values,
//even when mouse button not pressed.
#define MOUSE_NODOWN FALSE

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);

/*
#define DEFAULT_SCREEN_WIDTH 1600
#define DEFAULT_SCREEN_HEIGHT 900
#define SEEDS_COUNT 20

enum Attrib {
    ATTRIB_POS = 0,
    ATTRIB_COLOR,
    COUNT_ATTRIBS,
};

static Vector2 seed_positions[SEEDS_COUNT];
static Vector4 seed_colors[SEEDS_COUNT];
static Vector2 seed_velocities[SEEDS_COUNT];

float rand_float(void)
{
    return (float) rand() / RAND_MAX;
}

float lerpf(float a, float b, float t)
{
    return a+t*(b-a);
}

void generate_random_seeds(void)
{
    for (size_t i = 0; i < SEEDS_COUNT; ++i) {
        seed_positions[i].x = rand_float()*DEFAULT_SCREEN_WIDTH;
        seed_positions[i].y = rand_float()*DEFAULT_SCREEN_HEIGHT;
        seed_colors[i].x = rand_float();
        seed_colors[i].y = rand_float();
        seed_colors[i].z = rand_float();
        seed_colors[i].w = 1;

        float angle = rand_float()*2*M_PI;
        float mag = lerpf(100, 200, rand_float());
        seed_velocities[i].x = cosf(angle)*mag;
        seed_velocities[i].y = sinf(angle)*mag;
    }
}

void render_frame(double delta_time)
{
    for (size_t i = 0; i < SEEDS_COUNT; ++i) {
        float x = seed_positions[i].x + seed_velocities[i].x*delta_time;
        if (0 <= x && x <= DEFAULT_SCREEN_WIDTH) {
            seed_positions[i].x = x;
        } else {
            seed_velocities[i].x *= -1;
        }
        float y = seed_positions[i].y + seed_velocities[i].y*delta_time;
        if (0 <= y && y <= DEFAULT_SCREEN_HEIGHT) {
            seed_positions[i].y = y;
        } else {
            seed_velocities[i].y *= -1;
        }
    }
}

void interactive_mode(GLFWwindow *window)
{
    double prev_time = 0.0;
    double delta_time = 0.0f;

    while (!glfwWindowShouldClose(window)) {
        render_frame(delta_time);

        glfwSwapBuffers(window);
        glfwPollEvents();

        double cur_time = glfwGetTime();
        delta_time = cur_time - prev_time;
        prev_time = cur_time;
    }
}
*/
