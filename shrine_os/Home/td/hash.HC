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

#define CMD_CNT  47
#define CMD_ARGS  6

#define HFLAGS 0
#define HARGS  1

#define TOK_IDX   0
#define TOK_CMD   1
#define TOK_MIN   2
#define TOK_MAX   3
#define TOK_FMAX  4
#define TOK_ATYPE 5

#define ONLY_NONE  0
#define ONLY_DIRS  1
#define ONLY_FILES 2
#define ONLY_BOTH  3

/*HASH idx, command, token min, token max,
  flag max */
U8 *hashed[CMD_CNT][CMD_ARGS] = {
  {  7, "clear", 1, 1, 0, ONLY_NONE},
  { 23, "mkdir", 2, 2, 0, ONLY_DIRS},
  { 30, "rmdir", 2, 2, 1, ONLY_DIRS},
  { 35, "touch", 2, 2, 0, ONLY_BOTH},
  { 38, "tasks", 1, 1, 0, ONLY_NONE},
  { 43,   "cdd", 1, 2, 0, ONLY_DIRS},
  { 56,   "cat", 2, 2, 0, ONLY_FILES},
  { 60,   "man", 2, 2, 0, ONLY_NONE},
  { 61,   "pal", 1, 1, 1, ONLY_NONE},
  { 62,   "pid", 1, 1, 0, ONLY_NONE},
  { 63,   "mem", 1, 1, 0, ONLY_NONE},
  { 64,   "dir", 1, 2, 1, ONLY_BOTH},
  { 66,   "cls", 1, 1, 0, ONLY_NONE},
  { 67,   "ans", 1, 2, 0, ONLY_NONE},
  { 68,   "rnd", 1, 1, 0, ONLY_NONE},
  { 72,   "cpu", 1, 1, 1, ONLY_NONE},
  { 75,   "pwd", 1, 1, 0, ONLY_NONE},
  { 81,   "vol", 1, 1, 0, ONLY_NONE},
  { 84,   "now", 1, 1, 0, ONLY_NONE},
  { 86,   "run", 2, 2, 0, ONLY_FILES},
  {146,  "head", 2, 2, 0, ONLY_FILES},
  {153,  "diff", 3, 3, 0, ONLY_FILES},
  {158,  "date", 1, 1, 0, ONLY_NONE},
  {169,  "help", 1, 1, 0, ONLY_NONE},
  {170,  "tail", 2, 2, 0, ONLY_FILES},
  {174,  "grep", 2, 2, 1, ONLY_NONE},
  {176,  "tree", 1, 2, 0, ONLY_BOTH},
  {177,  "time", 1, 1, 0, ONLY_NONE},
  {179,  "more", 2, 2, 0, ONLY_FILES},
  {182,  "dump", 2, 2, 0, ONLY_FILES},
  {184,  "term", 1, 1, 0, ONLY_NONE},
  {186,  "exit", 1, 1, 0, ONLY_NONE},
  {187,  "view", 2, 2, 0, ONLY_FILES},
  {194,  "type", 2, 2, 0, ONLY_FILES},
  {195,  "quit", 1, 1, 0, ONLY_NONE},
  {199,    "cd", 1, 2, 0, ONLY_DIRS},
  {201,    "ed", 2, 2, 0, ONLY_FILES},
  {203,    "df", 1, 1, 0, ONLY_NONE},
  {208,  "tosz", 2, 2, 0, ONLY_FILES},
  {209,    "md", 2, 2, 0, ONLY_DIRS},
  {211,    "cp", 3, 3, 1, ONLY_BOTH},
  {212,    "fm", 1, 1, 0, ONLY_BOTH},
  {214,    "rd", 2, 2, 1, ONLY_DIRS},
  {223,    "ls", 1, 2, 1, ONLY_BOTH},
  {224,    "rm", 2, 2, 2, ONLY_BOTH},
  {227,    "mv", 3, 3, 0, ONLY_BOTH},
  {228,    "ps", 1, 1, 0, ONLY_NONE} //47
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

  //"%d\n",idx;
  for(;idx<HASH_TABLE_SIZE;idx++)
    if (!StrCmp(in->data[idx][TOK_CMD],cmd)) return idx;

  return -1;
}
Bool tk_minmax(CHCMDS *in,U64 idx,U64 val,U64 type=HARGS)
{ 
  if (type==HARGS)
    return in->data[idx][TOK_MIN]<=val<=in->data[idx][TOK_MAX];

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
}

CHCMDS *c=CAlloc(sizeof(CHCMDS));
  c->hashdx=&hashDX;
  c->parse=&parse;

  c->tk_minmax=&tk_minmax;
//  c->print_arr=&print_arr;

  c->parse(c);

// "%d\n",c->hashdx(c,"edp");

Free(hashed);
