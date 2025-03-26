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
      Draws 3D/shape objects.
*/
Cd(__DIR__);;

#define PARTICLE_MAX 0

#include "grdefs"

//#include "models/crobot"
//#include "models/wolf_plane"
//#include "models/tie_fighter"
//#include "models/zoid"
//#include "models/x-wing"
#include "models/shotgun"

#define FOV_ANGLE 45.0

I64 CUBE_DISTANCE=6;

//These are defined in each "model" file :start
/*#define MODEL_NAME "basic_shape"
#define OBJ_POINTS SHP_CUBE_POINTS
#define OBJ_EDGES SHP_CUBE_EDGES
CD3 *p_obj=&cube_points;
CD2 *v_obj=&cube_edges;*/
//:end

Bool draw_lines=FALSE; //Maybe a define and stick in each model

F64 p2DTop3D(F64 xy,F64 z)
{
  F64 angleRadians=(FOV_ANGLE/180.0)*M_PI;

  return xy/(z*Tan(angleRadians/2));
}

CD3 p_arr[OBJ_POINTS];
CD3 rotated;

U8 *TrueFalse(U64 bval)
{
  if (bval) return "TRUE";
  else return "FALSE";
}
U64 ls,le,fh=FONT_HEIGHT;
U0 DrawIt(CTask *task,CDC *dc)
{
  DCFill(dc,BLACK);

  dc->color=LTGREEN;

  GrPrint(dc,fh,fh,"Model: %s",MODEL_NAME);
  GrPrint(dc,fh,fh*2,"Mouse: (%2.8f,%2.8f)\n",rotation_x,rotation_y);
  GrPrint(dc,fh,fh*3,"Lines: %s",tf_arr[draw_lines]);

  for (ita=0;ita<OBJ_POINTS;ita++)
  {
    dc->color=p_arr[ita].z;
    GrPlot(dc,p_arr[ita].x,p_arr[ita].y);

//    GrPrint(dc,p_arr[ita].x,p_arr[ita].y,"%d",ita);
  }

  if (draw_lines)
  {
    for (ita=0;ita<OBJ_EDGES;ita++)
    {
      ls=v_obj[ita].x;le=v_obj[ita].y;

      GrLine(dc,p_arr[ls].x,p_arr[ls].y,p_arr[le].x,p_arr[le].y);
    }
  }
}

U0 AnimateTask(I64)
{
  while (TRUE)
  {
    for (ita=0;ita<OBJ_POINTS;ita++)
    {
      D3Copy(&rotated,&p_obj[ita]);

      rot_plot(&rotated);
      rotated.z+=CUBE_DISTANCE;

      p_arr[ita].x=p2DTop3D(rotated.x,rotated.z)*WIDTH+WIDTH/2;
      p_arr[ita].y=p2DTop3D(rotated.y,rotated.z)*HEIGHT+HEIGHT/2;

      if (p_arr[ita].x<WIDTH_CENTER-10-RandU16%10) p_arr[ita].z=LTGRAY;
      else p_arr[ita].z=GREEN;
    }

    Sleep(30);
  }
}

U0 Init()
{
  rotation_x=M_PI;
  rotation_y=0;
}

U0 ms_move()
{
  rotation_x=(ms.pos.y/WIDTH)*M_PI*2;
  rotation_y=(ms.pos.x/HEIGHT)*M_PI*2;
}
U0 key_down(){
  switch(ch)
  {
    case '\n':
      Init;
      break;
    case 'l':
      draw_lines=!draw_lines;
      break;
    case SC_CURSOR_UP:
      CUBE_DISTANCE-=1;
      break;
    case SC_CURSOR_DOWN:
      CUBE_DISTANCE+=1;
      break;
  };
}

MS_MOVE=&ms_move;
KEY_DOWN=&key_down;

ANIMATE_TASK=TRUE;
MOUSE_TRAP=TRUE;
MOUSE_NODOWN=TRUE;

#include "grmain"

//p_deinit(&p_arr,PARTICLE_MAX);

