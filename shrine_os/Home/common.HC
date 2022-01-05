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

class SV {
  U8 *begin;
  I64 size;
  I64 count;
  U8 *fp;
};

// tp : start
U0 SVTrim(SV *sv, Bool left = TRUE, Bool both = FALSE) {
  // Trims leading or trailing spaces from a string.
  // left = TRUE : left trim
  // left = FALSE : right trim
  // both = TRUE : left &right trim
  if (sv->size <= 0) return;

  if (left || both) {
    StrUtil(sv->begin, SUF_REM_LEADING);
  }

  if (!left || both) {
    StrUtil(sv->begin, SUF_REM_TRAILING);
  }

  sv->size = StrLen(sv->begin);
}

I64 SVWordCount(SV *sv, U8 delim = ' ') {
  if (sv->size <= 0) return 0;

  I64 word_count = 0, i = 0;

  while (i < sv->size) {
    if (sv->begin[i] == delim) word_count++;
    i++;
  }

  return word_count + 1;
}

U0 SVPullWord(SV *sv, U8 *out, U8 delim = ' ') {
  I64 i = 0;

  while (i < sv->size) {
    if (sv->begin[i] == delim) break;
    out[i] = sv->begin[i];
    i++;
  }

  out[i] = '\0';

  if (i<sv->size) {
    sv->begin += i+1;
    sv->size -= i+1;
  } else {
    sv->begin += i;
    sv->size -= i;
  }

  sv->count -= 1;
}

U64 HashCodeFor(U8 *str) {
  // Pretty basic. But, "effective"
  // hash code generator for strings.
  U64 hash = 0;
  U64 g = 31;
  U64 i;

  for (i=0; i < StrLen(str); i++) {
    hash = g * hash + str[i];
  }

  return hash;
}

Bool FileExists(U8 *file) {
  return FileFind(file,,FUF_JUST_FILES);
}

// tp : end


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
