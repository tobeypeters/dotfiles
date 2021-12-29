// This was just part of a AOC 2021 solution.
// Was just trying to figure out why somebodies
// code wasn't working. I got it to work.

#define SEGS_CNT 7

Bool NextPermutation(U8 *segs) {
  I64 length = SEGS_CNT - 1;

  I64 i = length;
  while (i > 0 && segs[i - 1] >= segs[i]) i--;

  if (i <= 0) return FALSE;

  I64 j = length;
  while (segs[j] <= segs[i - 1]) j--;

  SwapU8(&segs[i - 1], &segs[j]);

  j = length;
  while (i < j) {
    SwapU8(&segs[i], &segs[j]);
    j--; i++;
  }

  return TRUE;
}

U8 *segs = "abcdefg";

I64 d = 0;

"\nGenerate all permutations of [$FG$$FG,4$%s$FG$]:\n\nFirst: %s\n", segs, segs;
do {
  // I don't display the permutations as I go.
  // Cause, TempleOS has a limit on the amount of
  // terminal output lines it holds ... I guess?
  d++;
} while(NextPermutation(segs));

"Last: %s\n\nPermutaion Count: %d\n\n", segs, d;