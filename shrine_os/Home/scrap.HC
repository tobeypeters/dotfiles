
U0 test(U8 *buf) { 
  "%d\n", StrLen(&buf);
  "test() : %s, %s!!! \n", buf, buf;
}

U8 *buffer[3][12];


*buffer[0] = "Hello";
*buffer[1] = "World";
*buffer[2] = "car";

"buffer : %s, %s!!! AddressOf[buffer] : %d \n", *buffer[0], *buffer[1], &buffer;

test(*buffer);
