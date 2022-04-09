#define REC_CNT 32
U8 *VSAM[REC_CNT][7] =
{
/*
  Very poor implementation, of a hashtable.
  ID, token count min, token count max,
  file / dir validator, flag count min,
  flag count max
*/

{  0,  "view", 2, 2,  TRUE, 0, 0},
{  1,   "man", 2, 2, FALSE, 0, 0},
{  2,      "", 0, 0, FALSE, 0, 0},
{  3,  "date", 1, 1, FALSE, 0, 0},
{  4,    "ls", 1, 2,  TRUE, 0, 0},
{  5,      "", 0, 0, FALSE, 0, 0},
{  6,      "", 0, 0, FALSE, 0, 0},
{  7,      "", 0, 0, FALSE, 0, 0},
{  8,      "", 0, 0, FALSE, 0, 0},
{  9,      "", 0, 0, FALSE, 0, 0},
{ 10,      "", 0, 0, FALSE, 0, 0},
{ 11, "tasks", 1, 1, FALSE, 0, 0},
{ 12,    "cd", 1, 2,  TRUE, 0, 0},
{ 13,   "cpu", 1, 1, FALSE, 0, 1},
{ 14,    "ed", 2, 2, FALSE, 0, 0},
{ 15,    "df", 1, 1, FALSE, 0, 0},
{ 16,   "cdd", 1, 2,  TRUE, 0, 0},
{ 17,      "", 0, 0, FALSE, 0, 0},
{ 18,      "", 0, 0, FALSE, 0, 0},
{ 19,  "grep", 2, 2, FALSE, 0, 0},
{ 20,  "time", 1, 1, FALSE, 0, 0},
{ 21,  "tree", 1, 3,  TRUE, 0, 1},
{ 22,   "vol", 1, 1, FALSE, 0, 0},
{ 23,      "", 0, 0, FALSE, 0, 0},
{ 24,    "cp", 3, 3, FALSE, 0, 1},
{ 25,   "now", 1, 1, FALSE, 0, 0},
{ 26,   "run", 2, 2,  TRUE, 0, 0},
{ 27,    "rd", 2, 2,  TRUE, 0, 1},
{ 28, "mkdir", 2, 2, FALSE, 0, 0},
{ 29,   "cat", 2, 2,  TRUE, 0, 0},
{ 30,      "", 0, 0, FALSE, 0, 0},
{ 31,  "exit", 1, 1, FALSE, 0, 0},

{  3, "rmdir", 2, 2,  TRUE, 0, 1},
{  4,   "mem", 1, 1, FALSE, 0, 0},
{  4,    "rm", 2, 2,  TRUE, 0, 1},
{  8,  "quit", 1, 1, FALSE, 0, 0},
{  8, "touch", 2, 2, FALSE, 0, 0},
{ 12, "clear", 1, 1, FALSE, 0, 0},
{ 14,  "help", 1, 1, FALSE, 0, 0},
{ 24,    "fm", 1, 3,  TRUE, 0, 1},
{ 24,  "more", 2, 2,  TRUE, 0, 0},
{ 27,  "dump", 2, 2,  TRUE, 0, 0}

};

/*view  0
man   1
2
date  3
ls    4
5
6
7
mv    8
9
10
tasks 11
cd    12
cpu   13
ed    14
df    15
cdd   16
17
18
grep  19
time  20
tree  21
vol   22
23
cp    24
now   25
run   26
rd    27
mkdir 28
cat   29
30
exit  31

32 rmdir 3
33 mem   4
34 rm    4
35 quit  8
36 touch 8
37 clear 12
38 help  14
39 fm    24
40 more  24
41 dump  27
42
43
44
*/