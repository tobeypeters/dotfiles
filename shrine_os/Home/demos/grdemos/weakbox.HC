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

/*module.HC
  Description:
      Graphics module template.
*/
Cd(__DIR__);;

#define PARTICLE_MAX 8

#include "grdefs"

#define CUBE_DISTANCE 50
#define FOV_ANGLE 45
#define LINE_WIDTH 3

F64 p2DTop3D(F64 xy,F64 z)
{
  F64 angleRadians=(FOV_ANGLE/180)*M_PI;
  return xy/(z*Tan(angleRadians/2));
}

PARTICLE transformed[4], rotated;
U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);


//  F64 mouseXratio=(ms.pos.x/WIDTH)*M_PI,
//      mouseYratio=(ms.pos.y/HEIGHT)*M_PI;
  rotation_x=(ms.pos.x/WIDTH)*M_PI,
  rotation_y=(ms.pos.y/HEIGHT)*M_PI;

/*
CD3 cube_points[8]={
{-1.0,  1.0, -1.0}, //Top front left
{ 1.0,  1.0, -1.0}, //Top front right
{ 1.0, -1.0, -1.0}, //Bottom front right
{-1.0, -1.0, -1.0}, //Bottom front left
{-1.0,  1.0,  1.0}, //Top back left
{ 1.0,  1.0,  1.0}, //Top back right
{ 1.0, -1.0,  1.0}, //Bottom back right
{-1.0, -1.0,  1.0} //Bottom back left
};

CD2 cube_verts[12]={
  {0,1},{1,2},{2,3},{3,0},
  {4,5},{5,6},{6,7},{7,0},
  {0,4},{1,5},{2,6},{3,7},
};
*/
  for (ita=0;ita<8;ita++)
  {
      rotated=rot_plot(&FACES[i][j]);
      rotated.z += CUBE_DISTANCE;
      transformed[j].x=p2DTop3D(rotated.x, rotated.z);
      transformed[j].y=p2DTop3D(rotated.y, rotated.z);
  //      drawPolygon(renderer, transformed);
  }

/*void drawPolygon(SDL_Renderer *renderer, Point3D points[4]) {
    for (int i = 0; i < 4; i++) {
        int x1 = (points[i].x * WIDTH) + WIDTH / 2;
        int y1 = (points[i].y * HEIGHT) + HEIGHT / 2;
        int x2 = (points[(i + 1) % 4].x * WIDTH) + WIDTH / 2;
        int y2 = (points[(i + 1) % 4].y * HEIGHT) + HEIGHT / 2;
        SDL_RenderDrawLine(renderer, x1, y1, x2, y2);
    }
}
*/
}

U0 AnimateTask(I64)
{
  while (TRUE) {
    Sleep(20);
  }
}

U0 Init()
{
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
