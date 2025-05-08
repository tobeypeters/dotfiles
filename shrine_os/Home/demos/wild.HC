/* This code belongs to : omula : omulalalinistit *Discord*/

U8 chat[8] = {
    0b00101000,
    0b01000100,
    0b01000100,
    0b01000100,
    0b01111100,
    0b01000101,
    0b11111110,
    0b00000000,
};
text.font[129]=chat[0](U64);

U0 WildWestGame()
{
  "===%c WILD WEST ADVENTURE %c===\n\n",129,129;
  "You're a lone cowboy riding into the dusty town of Rusty Spur.\n"
  "Do you want to stop at the saloon ";

  if (YorN) {
    "\n"
    "You walk into the saloon. A piano is playing, and the bartender eyes you.\n"
    "Do you want to order a drink ";

    if (YorN) {
      "\n"
      "You sip some whiskey. A shady gambler challenges you to a card game.\n"
      "Do you accept the challenge ";

      if (YorN) {
        "\n"
        "You win the card game and earn the respect of the crowd!\n"
        "You're now a legend in Rusty Spur.\n";
      }
      else {
        "\n"
        "The gambler mocks you. You quietly leave the saloon with your pride intact.\n";
      }
    }
    else {
      "\n"
      "You decide to stay sober. Just then, a wanted outlaw walks in.\n"
      "Do you confront him ";

      if (YorN) {
        "\n"
        "With a quick draw, you shoot the outlaw and save the town!\n"
        "You're the new sheriff of Rusty Spur.\n";
      }
      else {
        "\n"
        "You duck behind the bar. The sheriff handles it. Maybe heroism isn't your thing.\n";
      }
    }
  }
  else {
    "\n"
    "You ride past town and head into the hills.\n"
    "A storm brews overhead. Do you seek shelter in a cave ";

    if (YorN) {
      "\n"
      "Inside the cave, you find a stash of gold left by bandits!\n"
      "You're rich beyond your wildest dreams.\n";
    }
    else {
      "\n"
      "You keep riding. Lightning strikes nearby, and your horse panics.\n"
      "You survive, but decide it's best to settle down in town after all.\n";
    }
  }

  "\n=== THE END ===\n\n"; PressAKey;
}

SettingsPush;

MenuPush(
  "File {"
  "  Abort(,CH_SHIFT_ESC);"
  "  Exit(,CH_ESC);"
  "}"
);

WinBorder;WinMax;
AutoComplete;
DocClear;

Fs->text_attr=RED<<4+LTRED;
WildWestGame;

MenuPop;

SettingsPop;

Kill(Fs);
