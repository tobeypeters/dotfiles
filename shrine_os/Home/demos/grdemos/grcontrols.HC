CCtrl *SpawnCtrl(U8 *name=NULL,U8 *label=NULL,CTask *task=sys_winmgr_task,
             U8 *dp,U8 *flags=NULL, U8 *lc=NULL,U8 rc=NULL,U8 *mw=NULL,
             I64 left=0,I64 top=0,I64 bottom=0,I64 right=0)
{ 
  CCtrl *res;

  res=ACAlloc(sizeof(CCtrl));

  res->name=StrNew(name);
  res->label=StrNew(label);

  res->win_task=task;

  res->flags=CTRLF_SHOW;

  if (flags)
    res->flags=res->flags|flags;

  res->type=CTRLT_GENERIC;

  res->draw_it=dp;
  res->left_click=lc;
  res->right_click=rc;
  res->wheel_chg=mw;


  res->left=left; res->right=right;
  res->top=top; res->bottom=bottom;

  res->light_border=DKGRAY;
  res->dark_border=LTGRAY;
//  res->light_border=LTGRAY;
//  res->dark_border=DKGRAY;
  res->bg=WHITE;
  res->fg=BLACK;

  QueIns(res,task->last_ctrl);
  TaskDerivedValsUpdate(task);

  return res;
}

/*
U0 LeftClickTermBttn(CCtrl *,I64,I64,Bool down)
{
  if (down)
    User;
}
*/