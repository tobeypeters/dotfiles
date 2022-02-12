//"\n";
//
//drv_free;
//drv_free('C');
//"C free %7.2f%%\n",drv_free('C',TRUE);
//drv_free(,TRUE);
//
//"\n";

#include "shared.HC"

#define HASH_CNT 31
U8 *hashes[HASH_CNT][7] =
{
/*ID, token count min, token count max,
file / dir validator, flag count min,
flag count max*/

{496,   "cd",    "~", 1, 2,  TRUE, 0, 0},
{502,   "df",     "", 1, 1, FALSE, 0, 0},
{504,   "ed",     "", 2, 2, FALSE, 0, 0},
{508,   "cp",   "-d", 3, 3,  TRUE, 0, 1},
{517,   "fm",   "-f", 1, 2,  TRUE, 0, 0},
{547,   "ls",     "", 1, 2,  TRUE, 0, 0},
{554,   "mv",     "", 3, 3, FALSE, 0, 0},
{556,   "rd",     "", 2, 2,  TRUE, 0, 1},
{565,   "rm",     "", 2, 2,  TRUE, 0, 1},
{2084,  "cdd",   "~", 1, 2,  TRUE, 0, 0},
{2088,  "cat",    "", 2, 2,  TRUE, 0, 0},
{2149,  "cpu",  "-f", 1, 1, FALSE, 0, 1},
{2242,  "man",    "", 2, 2, FALSE, 0, 0},
{2257,  "mem",    "", 1, 1, FALSE, 0, 0},
{2323,  "now",    "", 1, 1, FALSE, 0, 0},
{2402,  "run",    "", 2, 2,  TRUE, 0, 0},
{2440,  "vol",    "", 1, 1, FALSE, 0, 0},
{8517,  "date",   "", 1, 1, FALSE, 0, 0},
{8816,  "help",   "", 1, 1, FALSE, 0, 0},
{8820,  "dump",   "", 2, 2,  TRUE, 0, 0},
{8920,  "exit",   "", 1, 1, FALSE, 0, 0},
{8932,  "grep",   "", 2, 2, FALSE, 0, 0},
{9309,  "more",   "", 2, 2,  TRUE, 0, 0},
{9640,  "quit",   "", 1, 1, FALSE, 0, 0},
{9641,  "time",   "", 1, 1, FALSE, 0, 0},
{9753,  "tree", "-f", 1, 2,  TRUE, 0, 1},
{9755,  "view",   "", 2, 2,  TRUE, 0, 0},
{34374, "clear",  "", 1, 1, FALSE, 0, 0},
{36886, "mkdir",  "", 2, 2, FALSE, 0, 0},
{38294, "rmdir",  "", 2, 2,  TRUE, 0, 1},
{39172, "touch",  "", 2, 2, FALSE, 0, 0}

};

I64 indexOf(U8 *cmd) {
  U64 i = 0,
      m = 0;

  for (;i<HASH_CNT;i++) {
    //
  }

  return -1;
}

U64 i = 0;

for (;i<HASH_CNT;i++) {
  "%d\n", HashCodeFor(hashes[i][0]);
}

"len %d\n", Size(hashes);

Free(hashes);



