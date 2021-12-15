// Here we keep common code that is
// shared across all of the solutions

class SV {
  I64 size;
  U8 *begin;
};

I64 SVChopI64(SV *sv, I64 radix=10) {
  U8 *endp;
  I64 result = Str2I64(sv->begin, radix, &endp);
  sv->size -= endp - sv->begin;
  sv->begin = endp;
  return result;
}

Bool IsAlpha(U8 x) {
  return 'a' <= x <= 'z' || 'A' <= x <= 'Z';
}

Bool IsDigit(U8 x) {
  return '0' <= x <= '9';
}

Bool IsAlnum(U8 x) {
  return IsAlpha(x) || IsDigit(x);
}

Bool IsSpace(U8 x) {
  U8 *ws = " \n";
  while (*ws != 0) {
    if (*ws == x) {
       return TRUE;
    }
    ws++;
  }
  return FALSE;
}

U0 SVTrim(SV *sv, Bool left = TRUE) {
  if (left) {
    StrUtil(sv->begin, SUF_REM_LEADING);
  }
  else {
    StrUtil(sv->begin, SUF_REM_TRAILING);
  }

  sv->size = StrLen(sv->begin);
}


U0 SVChopWord(SV *input, SV *word) {
  I64 i = 0;
  while (i < input->size && IsAlnum(input->begin[i])) {
    i++;
  }
  word->begin = input->begin;
  word->size = i;
  input->begin += i;
  input->size -= i;
}

U0 SVChopLeft(SV *sv, I64 n=1)
{
  sv->begin += n;
  sv->size -= n;
}

U0 SVChopByDelim(SV *sv, U8 delim, SV *out)
{
  I64 i=0;
  while (i<sv->size && sv->begin[i] != delim) i++;

  out->begin = sv->begin;
  out->size = i;

  if (i<sv->size) {
    sv->begin += i+1;
    sv->size -= i+1;
  } else {
    sv->begin += i;
    sv->size -= i;
  }
}

U0 PrintSV(SV *sv)
{
  I64 i;
  for (i=0; i<sv->size; ++i) "%c", sv->begin[i];
}

Bool SVEq(SV *a, SV *b)
{
  if (a->size == b->size) {
    return MemCmp(a->begin, b->begin, a->size) == 0;
  }

  return FALSE;
}
