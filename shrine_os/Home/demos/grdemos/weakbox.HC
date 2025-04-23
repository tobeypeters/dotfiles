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

#include "models/crobot"
//#include "models/wolf_plane"
//#include "models/tie_fighter"
//#include "models/zoid"
//#include "models/x-wing"
//#include "models/shotgun"
//#include "models/zombicide"

#define FOV_ANGLE 90.0

I64 CUBE_DISTANCE=100;

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

  for (ida=0;ida<OBJ_POINTS;ida++)
  {
    dc->color=p_arr[ida].z;
    GrPlot(dc,p_arr[ida].x,p_arr[ida].y);

//    GrPrint(dc,p_arr[ida].x,p_arr[ida].y,"%d",ida);
  }

  if (draw_lines)
  {
    for (ida=0;ida<OBJ_EDGES;ida++)
    {
      ls=v_obj[ida].x;le=v_obj[ida].y;

      GrLine(dc,p_arr[ls].x,p_arr[ls].y,p_arr[le].x,p_arr[le].y);
    }
  }
}

U0 AnimateTask(I64)
{
  while (TRUE)
  {
    for (iaa=0;iaa<OBJ_POINTS;iaa++)
    {
      D3Copy(&rotated,&p_obj[iaa]);

      rot_plot(&rotated);
      rotated.z+=CUBE_DISTANCE;

      p_arr[iaa].x=p2DTop3D(rotated.x,rotated.z)*WIDTH+WIDTH/2;
      p_arr[iaa].y=p2DTop3D(rotated.y,rotated.z)*HEIGHT+HEIGHT/2;

      if (p_arr[iaa].x<WIDTH_CENTER-10-RandU16%10) p_arr[iaa].z=LTGRAY;
      else p_arr[iaa].z=GREEN;
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
  rotation_x=(cur_mouse_y/WIDTH)*M_PI*2;
  rotation_y=(cur_mouse_x/HEIGHT)*M_PI*2;
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

Fs->win_inhibit|=WIG_DBL_CLICK;

#include "grmain"

p_init;
