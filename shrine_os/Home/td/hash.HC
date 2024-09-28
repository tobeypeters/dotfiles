/*
  The MIT License(MIT)
  Copyright(c), Tobey Peters, https://github.com/tobeypeters
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
  and associated documentation files (the "Software"), to deal in the Software without restriction,
  including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
  subject to the following conditions:
  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*hash.HC
  Description:
      Build a command array, from a hash table.
*/

#define HASH_TABLE_SIZE 256

#define CMD_CNT  45
#define CMD_ARGS  5

#define HFLAGS 0
#define HARGS  1

/*HASH idx, command, token min, token max,
  flag max */
U8 *hashed[CMD_CNT][CMD_ARGS] = {
  {  7, "clear", 1, 1, 0},
  { 23, "mkdir", 2, 2, 0},
  { 30, "rmdir", 2, 2, 1},
  { 35, "touch", 2, 2, 0},
  { 38, "tasks", 1, 1, 0},
  { 43,   "cdd", 1, 2, 0},
  { 56,   "cat", 2, 2, 0},
  { 60,   "man", 2, 2, 0},
  { 61,   "pal", 1, 1, 1},
  { 63,   "mem", 1, 1, 0},
  { 66,   "cls", 1, 1, 0},
  { 67,   "ans", 1, 2, 0},
  { 68,   "rnd", 1, 1, 0},
  { 72,   "cpu", 1, 2, 1},
  { 75,   "pwd", 1, 1, 0},
  { 81,   "vol", 1, 1, 0},
  { 84,   "now", 1, 1, 0},
  { 86,   "run", 2, 2, 0},
  {146,  "head", 2, 2, 0},
  {153,  "diff", 3, 3, 0},
  {158,  "date", 1, 1, 0},
  {169,  "help", 1, 1, 0},
  {170,  "tail", 2, 2, 0},
  {174,  "grep", 2, 3, 1},
  {176,  "tree", 1, 2, 0},
  {177,  "time", 1, 1, 0},
  {179,  "more", 2, 2, 0},
  {182,  "dump", 2, 2, 0},
  {184,  "term", 1, 1, 0},
  {186,  "exit", 1, 1, 0},
  {187,  "view", 2, 2, 0},
  {194,  "type", 2, 2, 0},
  {195,  "quit", 1, 1, 0},
  {199,    "cd", 1, 2, 0},
  {201,    "ed", 2, 2, 0},
  {203,    "df", 1, 1, 0},
  {208,  "tosz", 2, 2, 0},
  {209,    "md", 2, 2, 0},
  {211,    "cp", 3, 3, 1},
  {212,    "fm", 1, 1, 0},
  {214,    "rd", 2, 2, 1},
  {223,    "ls", 1, 2, 1},
  {224,    "rm", 2, 2, 2},
  {227,    "mv", 3, 3, 0},
  {228,    "ps", 1, 1, 0} //45
};

class CHCMDS
{
  U8 *data[HASH_TABLE_SIZE+1][CMD_ARGS];

  I64 (* hashdx)(CHCMDS *in,U8 *cmd);
  U0 (* parse)(CHCMDS *in);

  Bool (* tk_minmax)(CHCMDS *in,U64 idx,U64 val,U64 type=HARGS);

  U0 (* print_arr)(CHCMDS *in);
};
I64 hashDX(CHCMDS *in,U8 *cmd)
{//Return the index in the hash table, fo a given command.
  I64 idx=0;

  if (!cmd) return idx;

  U64 hash=0;

  U8 *p=cmd;
  while (*p) hash+=*p++;
  idx=hash%HASH_TABLE_SIZE;

//  "%d\n",idx;
  for(;idx < HASH_TABLE_SIZE;idx++)
    if (!StrCmp(in->data[idx][1],cmd)) return idx;

  return -1;
}
Bool tk_minmax(CHCMDS *in,U64 idx,U64 val,U64 type=HARGS)
{ 
  if (type==HARGS)
    return in->data[idx][2]<=val<=in->data[idx][3];

  if (type==HFLAGS)
    return 0<=val<=in->data[idx][4];

  return FALSE;
}
/*U0 print_arr(CHCMDS *in)
{
  U64 i=0;

  for(;i<HASH_TABLE_SIZE;i++)
    if (in->data[i][0]) "%3d%6s%2d%2d%2d\n",in->data[i][0],in->data[i][1],in->data[i][2],in->data[i][3],in->data[i][4];
}*/
U0 parse(CHCMDS *in)
{
  U64 h,i,j;

  for(i=0;i<CMD_CNT;i++)
  {
    h=hashed[i][0];

    for(j=0;j<CMD_ARGS;j++)
      in->data[h][j]=hashed[i][j];
  }
  //in->print_arr(in);

  MemSet(hashed,'\0',sizeof(U8)*HASH_TABLE_SIZE*CMD_ARGS);
  Free(hashed);

}

CHCMDS *c=CAlloc(sizeof(CHCMDS));
  c->hashdx=&hashDX;
  c->parse=&parse;

  c->tk_minmax=&tk_minmax;
//  c->print_arr=&print_arr;

  c->parse(c);
