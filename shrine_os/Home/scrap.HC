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
U8 *hashes[HASH_CNT][8] =
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
I64 cur_IDX = -1;

I64 indexOf(U8 *cmd) {
  U64 i = 0,
      h = 0;

  h = HashCodeFor(cmd);

  for (;i<HASH_CNT;i++) {
    if (hashes[i][0] == h) {
      return i;
    }
  }

  return -1;
}

U64 tc = 3,
    fc = 1;

//Yes, I'm handing error checking and validation HORRIBLY.
U0 err_print(U8 *msg, U8 *link="Usage")
{//Print our err_msg.
  "`$FG,3$%s$FG$`: %s ...\n", link, msg;
}

Bool err_check(U64 tcmin=1, U64 tcmax=1,
	       Bool existance_check=FALSE,
	       U64 fcmin=0, U64 fcmax=0)
{//Cheap error checker.
  if (tc < tcmin || tc > tcmax) {
    err_print("Invalid number of arguments provided");
    return FALSE;
  }

  if (fc < fcmin || fc > fcmax) {
    err_print("Invalid number of options provided");
    return FALSE;
  }

  if (existance_check && tcmax > 1) //Added tcmax check. Probably not needed.
  {//Make sure all files & directories exist.
    U64 i = begin, //begin should already be 1.
        l = 0,
        h = 0;

    while (i <= links) {
      if (!(chain[i][0] == '-')) {
        l = StrLen(chain[i]);

        //Are we changing to another mounted drive?
        if (l == 2 && chain[i][1] == ':') {
          h = HashCodeFor(chain[i]);

          if (445<h<547 || 317<h<419) { //a:..z: or A:..Z:
            if (!drv_valid(chain[i][0])) {
              goto drv_error;
            }
            goto drv_change;
          }
          else {
            goto drv_error;
          }

          drv_error:
            err_print("invalid drive specified or drive is currently not mounted",chain[i]);
            return FALSE;

          goto drv_change;
        }

        if (l == 1 && chain[i][0] == 47) { //FileFInd doesn't "/"
        }
        else {
          if (!FileFind(chain_peek(,i))) {
            err_print("does not exist",chain[i]);
            return FALSE;
          }
        }
        drv_change:
      }

      i++;
    }
  }

  return TRUE;
}


"len %d\n", Size(hashes);

cur_IDX = indexOf("date");

"i %d\n",cur_IDX;

if (cur_IDX > -1) { 
  "index %d value %s\n", i, hashes[cur_IDX][1];
}


Free(hashes);

