#define HASH_TABLE_SIZE 256

#define CMD_CNT  33
#define CMD_ARGS  6

U8 *cmds[HASH_TABLE_SIZE][CMD_ARGS];

/*HASH idx, command, token min, token max,
  validate file(s) / dir{s}, flag max */
U8 *hashed[CMD_CNT][CMD_ARGS] = {
  { 56,   "cat", 2, 2, 1, 0},
  {199,    "cd", 1, 2, 1, 0},
  { 43,   "cdd", 1, 2, 1, 0},
  {  7, "clear", 1, 1, 0, 0},
  {211,    "cp", 3, 3, 0, 1},
  { 72,   "cpu", 1, 1, 0, 1},
  {158,  "date", 1, 1, 0, 0},
  {202,    "df", 1, 1, 0, 0},
  {182,  "dump", 2, 2, 1, 0},
  {201,    "ed", 2, 2, 0, 0},
  {186,  "exit", 1, 1, 0, 0},
  {212,    "fm", 1, 3, 1, 1},
  {174,  "grep", 2, 2, 0, 0},
  {169,  "help", 1, 1, 0, 0},
  {223,    "ls", 1, 2, 0, 0},
  { 60,   "man", 2, 2, 0, 0},
  { 63,   "mem", 1, 1, 0, 0},
  { 23, "mkdir", 2, 2, 0, 0},
  {179,  "more", 2, 2, 1, 0},
  {127,    "mv", 3, 3, 0, 0},
  { 84,   "now", 1, 1, 0, 0},
  {195,  "quit", 1, 1, 0, 0},
  {214,    "rd", 2, 2, 1, 1},
  {224,    "rm", 2, 2, 1, 1},
  { 30, "rmdir", 2, 2, 1, 1},
  { 85,   "run", 2, 2, 1, 0},
  { 38, "tasks", 1, 1, 0, 0},
  {184,  "term", 1, 1, 0, 0},
  {175,  "time", 1, 1, 0, 0},
  { 35, "touch", 2, 2, 0, 0},
  {176,  "tree", 1, 2, 1, 0},
  {187,  "view", 2, 2, 1, 0},
  { 81,   "vol", 1, 1, 0, 0}
};

class CHCMDS
{
  U8 *data[HASH_TABLE_SIZE][CMD_ARGS];

  I64 (* hashdx)(U8 *cmd);
  U0 (* parse)(CHCMDS *in);

  U0 (* print_arr)(CHCMDS *in);  
};
I64 hashDX(U8 *cmd)
{//Return the index in the hash table, fo a given command.
  U64 hash=0, 
      idx=0;

  while (*cmd) hash+=*cmd++;
  idx=hash % HASH_TABLE_SIZE;

  for(idx=0;idx < HASH_TABLE_SIZE;idx++)
  {
    if (!StrCmp(cmds[idx][1],cmd)) return idx;
  }

  return -1;
}
U0 print_arr(CHCMDS *in)
{
  U64 i;

  for(;i<HASH_TABLE_SIZE;i++)
    if (in->data[i][0]) "%3d%6s%2d%2d%2d%2d\n",in->data[i][0],in->data[i][1],in->data[i][2],in->data[i][3],in->data[i][4],in->data[i][5];
}
U0 parse(CHCMDS *in)
{
  U64 h,i,j;

  for(i=0;i<CMD_CNT;i++)
  {
    h=hashed[i][0];

    for(j=0;j<CMD_ARGS;j++)
      in->data[h][j]=hashed[i][j];
  }
  in->print_arr(in);

  MemSet(hashed, '\0', sizeof(U8)*HASH_TABLE_SIZE*CMD_ARGS);
  Free(hashed);

}
CHCMDS *c = CAlloc(sizeof(CHCMDS));
  c->hashdx=&hashDX;
  c->parse=&parse;
  c->print_arr=&print_arr;

  c->parse(c);
Free(c);

//MemCpy(????);
/*First value is the index of the array, I need to put the values;
{

  {  7, "clear", 1, 1, FALSE, 0, 0},
  { 23, "mkdir", 2, 2, FALSE, 0, 0},
  { 30, "rmdir", 2, 2,  TRUE, 0, 1},
  { 35, "touch", 2, 2, FALSE, 0, 0},
  { 38, "tasks", 1, 1, FALSE, 0, 0},
  { 43,   "cdd", 1, 2,  TRUE, 0, 0},
  { 56,   "cat", 2, 2,  TRUE, 0, 0},
  { 60,   "man", 2, 2, FALSE, 0, 0},
  { 63,   "mem", 1, 1, FALSE, 0, 0},
  { 72,   "cpu", 1, 1, FALSE, 0, 1},
  { 81,   "vol", 1, 1, FALSE, 0, 0},
  { 84,   "now", 1, 1, FALSE, 0, 0},
  { 85,   "run", 2, 2,  TRUE, 0, 0},
  {127,    "mv", 3, 3, FALSE, 0, 0},
  {158,  "date", 1, 1, FALSE, 0, 0},
  {169,  "help", 1, 1, FALSE, 0, 0},
  {174,  "grep", 2, 2, FALSE, 0, 0},
  {175,  "time", 1, 1, FALSE, 0, 0},
  {176,  "tree", 1, 2,  TRUE, 0, 0},
  {179,  "more", 2, 2,  TRUE, 0, 0},
  {182,  "dump", 2, 2,  TRUE, 0, 0},
  {184,  "term", 1, 1, FALSE, 0, 0}
  {186,  "exit", 1, 1, FALSE, 0, 0},
  {187,  "view", 2, 2,  TRUE, 0, 0},
  {195,  "quit", 1, 1, FALSE, 0, 0},
  {199,    "cd", 1, 2,  TRUE, 0, 0},
  {201,    "ed", 2, 2, FALSE, 0, 0},
  {202,    "df", 1, 1, FALSE, 0, 0},

  {211,    "cp", 3, 3, FALSE, 0, 1},
  {211,    "fm", 1, 3,  TRUE, 0, 1},

  {214,    "rd", 2, 2,  TRUE, 0, 1},

  {223,    "ls", 1, 2, FALSE, 0, 0},
  {223,    "rm", 2, 2,  TRUE, 0, 1},
};
*/

//Free(cmds);