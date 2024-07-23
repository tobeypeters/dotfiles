U0 Main()
{
  U8 *Menu_Select=NULL;
  U8 *input=NULL;

 menu:
  "\nMain Menu\n";
  "------ --\n";
  "1. Run\n";
  "2. Exit\n\n";

  Menu_Select=GetStr("Would you like to run this program?: ");

  if (!StrCmp(Menu_Select,"1")) goto run_game;
  if (!StrCmp(Menu_Select,"2")) goto term_game;
  else goto menu;

 run_game:
  DocClear;
  input=GetStr("\nWhat is your name?: ");
  "\n\n%s is a silly egghead!\n\n\n\n\n\n\n\n\n",input;
  PressAKey();
  term_game:
  "\n";

}

Main();
