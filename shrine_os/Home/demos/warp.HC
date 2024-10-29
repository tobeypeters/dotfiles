#define WIDTH GR_WIDTH
#define HEIGHT GR_HEIGHT

#define STAR_COUNT 500 // Number of stars

class Star
{
  F64  x,y,     // Current position of the star
     angle,    // Angle of movement from the center
     speed,    // Speed of the star
  distance; // Distance from the center

  F64 color,
      px,py;
} stars[STAR_COUNT];

U8 COLORS[3]={YELLOW,RED,WHITE};

U0 InitStar(U64 i)
{
  stars[i].x=WIDTH/2;
  stars[i].y=HEIGHT/2;
  stars[i].angle=(RandU16%360)*(ã/180.0); //Random angle in radians
//  stars[i].speed=(RandU16%50)/50.0+0.5;   //Random speed
  stars[i].speed=RandU16%50;   //Random speed
  stars[i].distance=0;                    //Start at the center
  stars[i].color=RandU16%3;

  stars[i].px=stars[i].x;
  stars[i].py=stars[i].y;
}
U0 Init()
{
  U64 i;

  for (i=0;i<STAR_COUNT;i++) InitStar(i);
}
U0 updateStars()
{
  U64 i;

  for (i=0;i<STAR_COUNT;i++)
  {
    // Increase the distance, which simulates moving outward
    stars[i].distance+=stars[i].speed;

    stars[i].px=stars[i].x;
    stars[i].py=stars[i].y;

    // Update x and y based on angle and distance from the center
    stars[i].x=WIDTH/2+Cos(stars[i].angle)*stars[i].distance;
    stars[i].y=HEIGHT/2+Sin(stars[i].angle)*stars[i].distance;

    // Reset star if it goes out of bounds
    if (stars[i].px<0||stars[i].px>WIDTH||
        stars[i].py<0||stars[i].py>HEIGHT) {
      InitStar(i);
    }
  }
}
U0 displayStarfield(CDC *dc)
{
  U64 i,j;

U64 x,y;
  for (i=0;i<STAR_COUNT;i++) {
    x=stars[i].x;
    y=stars[i].y;
    dc->color=COLORS[stars[i].color];
    GrPlot(dc,stars[i].x,stars[i].y);
    GrLine(dc,stars[i].x,stars[i].y,
              stars[i].px,stars[i].py);
  }
}
U0 DrawIt(CTask *task,CDC *dc)
{
  displayStarfield(dc);
  updateStars;
}

U0 Warp()
{
  I64 ch,sc;
  MenuPush(
	"File {"
	"  Abort(,CH_SHIFT_ESC);"
	"  Exit(,CH_ESC);"
	"}"
	"Play {"
	"  Restart(,'\n');"
	"}"
	);
  SettingsPush;
  AutoComplete;
  WinBorder;
  WinMax;
  DocCursor;
  DocClear;

  Init;

//  Fs->animate_task=Spawn(&AnimateTask,NULL,"Animate",,Fs);
  Fs->draw_it=&DrawIt;
  try {
    do
      switch (ch=GetKey(&sc)) {
	case '\n':
	  Init;
	  break;
      }
    while (ch!=CH_ESC && ch!=CH_SHIFT_ESC);
  } catch
    PutExcept;

//  cdc=NULL;

  SettingsPop;
  MenuPop;
//  DCDel(cdc);
}

Warp;
