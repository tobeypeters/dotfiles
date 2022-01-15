U0 test(U64 addr_buff1) {
  U64 *p = addr_buff1;
 
  "test() : %s, %s!!! \n", p[0], p[1];
}

U8 *buffer[2][12];

*buffer[0] = "Hello";
*buffer[1] = "World";

"buffer : %s, %s!!! AddressOf[buffer] : %d \n", *buffer[0], *buffer[1], &buffer;

test(&buffer);
