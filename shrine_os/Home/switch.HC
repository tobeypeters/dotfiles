// I'm using an I64 and I want to use a switch on a number.
I64 a = 2;

// Works
/*switch (a) {
  case 0:
    "0\n";
    break;
  case 2:
    "2\n";
    break;
  default:
    break;
}*/

// Doesn't work
switch (a) {
  case 0:
    "0\n";
    break;
  case 2:
    "2\n";
    break;
  case 99998:
    "99998\n";
    break;
  default:
    break;
}

// Doesn't work;
/*  switch (2) {
    case 0:
      "one\n";
      break;
    case 99998:
      "two\n";
      break;
    default:
  }*/

