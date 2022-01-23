/*
U0 test(U64 x = 3, U64 y = 0, ...) {
  "%d %d\n",x,y;

  U64 i;

  for (i=0; i < argc; i++) {
    "%d\n", argv[i];
  }
}

test(5,,"viper",12,"butt",43);

test();
*/

U8 *test = __DIR__ + "templeDOS.HC";

"test [%s]\n", test;