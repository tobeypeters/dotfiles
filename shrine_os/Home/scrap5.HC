#define HASH_TABLE_SIZE 256 // Increased size of the hash table

U8 *cmds[HASH_TABLE_SIZE][7];
MemSet(cmds, '\0', sizeof(U8)*HASH_TABLE_SIZE*7);

cmds[56]

/*First value is the index of the array, I need to put the values;
{
 
  { 56,   "cat", 2, 2,  TRUE, 0, 0},
  {199,    "cd", 1, 2,  TRUE, 0, 0},
  { 43,   "cdd", 1, 2,  TRUE, 0, 0},
  {  7, "clear", 1, 1, FALSE, 0, 0},
  {211,    "cp", 3, 3, FALSE, 0, 1},
  { 72,   "cpu", 1, 1, FALSE, 0, 1},
  {158,  "date", 1, 1, FALSE, 0, 0},
  {202,    "df", 1, 1, FALSE, 0, 0},
  {182,  "dump", 2, 2,  TRUE, 0, 0},
  {201,    "ed", 2, 2, FALSE, 0, 0},
  {186,  "exit", 1, 1, FALSE, 0, 0},
  {211,    "fm", 1, 3,  TRUE, 0, 1},
  {174,  "grep", 2, 2, FALSE, 0, 0},
  {169,  "help", 1, 1, FALSE, 0, 0},
  {223,    "ls", 1, 2, FALSE, 0, 0},
  { 60,   "man", 2, 2, FALSE, 0, 0},
  { 63,   "mem", 1, 1, FALSE, 0, 0},
  { 23, "mkdir", 2, 2, FALSE, 0, 0},
  {179,  "more", 2, 2,  TRUE, 0, 0},
  {127,    "mv", 3, 3, FALSE, 0, 0},
  { 84,   "now", 1, 1, FALSE, 0, 0},
  {195,  "quit", 1, 1, FALSE, 0, 0},
  {214,    "rd", 2, 2,  TRUE, 0, 1},
  {223,    "rm", 2, 2,  TRUE, 0, 1},
  { 30, "rmdir", 2, 2,  TRUE, 0, 1},
  { 85,   "run", 2, 2,  TRUE, 0, 0},
  { 38, "tasks", 1, 1, FALSE, 0, 0},
  {184,  "term", 1, 1, FALSE, 0, 0}
  {175,  "time", 1, 1, FALSE, 0, 0},
  { 35, "touch", 2, 2, FALSE, 0, 0},
  {176,  "tree", 1, 2,  TRUE, 0, 0},
  {187,  "view", 2, 2,  TRUE, 0, 0},
  { 81,   "vol", 1, 1, FALSE, 0, 0},
};
*/

Free(cmds);