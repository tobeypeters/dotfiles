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

/*weakbox.HC
  Description:
      Draws shape objects.
*/
Cd(__DIR__);;

#define PARTICLE_MAX 0

#include "grdefs"

#define CUBE_DISTANCE 24
#define FOV_ANGLE 45.0

#define OBJ_POINTS SHP_CUBE_POINTS
#define OBJ_VERTS  SHP_CUBE_VERTS
//#define OBJ_POINTS SHP_PYRAMID_POINTS
//#define OBJ_VERTS  SHP_PYRAMID_VERTS

CD3 *p_obj=&cube_points;
CD2 *v_obj=&cube_verts;

F64 p2DTop3D(F64 xy,F64 z)
{
  F64 angleRadians=(FOV_ANGLE/180.0)*M_PI;

  return xy/(z*Tan(angleRadians/2));
}

CD2 p_arr[OBJ_POINTS];
CD3 rotated;

U64 ls,le;

Bool once=TRUE;

ADocClear;AdamLog("\n");
U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  dc->color=LTRED;

  GrPrint(dc,10,10,"Mouse: (%2.8f,%2.8f)\n",rotation_x,rotation_y);

  rotation_x=0;
  rotation_y=0;

  for (ita=0;ita<OBJ_POINTS;ita++)
  {
if (once)
{
AdamLog("%2.4f %2.4f %2.4f\n",p_obj[ita].x,p_obj[ita].y,p_obj[ita].z);
  once=FALSE;
}
    D3Copy(&rotated,&p_obj[ita]);

    rot_plot(&rotated);
    rotated.z+=CUBE_DISTANCE;

    p_arr[ita].x=p2DTop3D(rotated.x,rotated.z)*WIDTH+WIDTH/2;
    p_arr[ita].y=p2DTop3D(rotated.y,rotated.z)*HEIGHT+HEIGHT/2;

if (once)    
AdamLog("%2.4f %2.4f\n",p_arr[ita].x,p_arr[ita].y);

    GrPrint(dc,p_arr[ita].x,p_arr[ita].y,"%d",ita);
  }
if (once) once=FALSE;

  for (ita=0;ita<OBJ_VERTS;ita++)
//  for (ita=0;ita<1;ita++)
  {
    ls=v_obj[ita].x;le=v_obj[ita].y;

    GrLine(dc,p_arr[ls].x,p_arr[ls].y,p_arr[le].x,p_arr[le].y);
  }
}

U0 AnimateTask(I64)
{
  while (TRUE) {
    Sleep(20);
  }
}

U0 Init()
{
  rotation_x=WIDTH_CENTER;
  rotation_y=HEIGHT_CENTER;
}

U0 MS_L_DOWN(){}
U0 MS_L_UP(){}
U0 MS_MOVE()
{
  rotation_x=(ms.pos.y/WIDTH)*M_PI*2;
  rotation_y=(ms.pos.x/HEIGHT)*M_PI*2;
}
U0 MS_MOVE_LDOWN(){}
U0 MS_MOVE_RDOWN(){}
U0 MS_R_DOWN(){}
U0 MS_R_UP(){}
U0 KEY_DOWN(){}

#define ANIMATE_TASK FALSE

#define MOUSE_TRAP TRUE

//Update mouse postion values,
//even when mouse button not pressed.
#define MOUSE_NODOWN TRUE

#include "grmain"

p_deinit(&p_arr,PARTICLE_MAX);

