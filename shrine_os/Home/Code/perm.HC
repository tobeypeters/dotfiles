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
    j--;
    i++;
  }

  return TRUE;
}

U8 *segs = "abcdefg";

I64 d = 0;

do {
  d++;
} while(NextPermutation(segs));

"\nPermutaion Count: %d\n", d;
