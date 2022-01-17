U0 token_trim(U8 *str, Bool left = TRUE, Bool both = FALSE)
{//Trims leading or trailing spaces from a string.
 //left = TRUE : left trim
 //left = FALSE : right trim
 //both = TRUE : left &right trim
  if (StrLen(str) == 0) return;

  if (left || both) {
    StrUtil(str, SUF_REM_LEADING);
  }

  if (!left || both) {
    StrUtil(str, SUF_REM_TRAILING);
  }
}

U64 token_count(U8 *str, Bool count_words = TRUE, U8 delim = ' ')
{//Count the occurences of either the words or a specific char.
  U64 l = StrLen(str);

  if (l == 0) return 0;

  U64 i = 0,
  count = 0;

  while (i < l) {
    if (str[i] == delim) {
      count++;
    }

    i++;
  }

  return count + count_words;
}


U8 stack[256][256];
U64 count = 0;

U64 stack_push(U8 *si, U8 delim = ' ')
{//Push an item, onto the stack.
  U64 i = 0;

  while (si[0] != '\0' && si[0] != delim) {
    stack[count][i] = si[0];
    "%c", si[0];
    si++; i++;
  }
  if (i > 0) stack[count][i] = '\0';
  
  count++;  

  while (*si == delim) si++;

  return si;
}

U8 stack_peek(U64 idx)
{//Peek at a value on the stack.
 if (count > 0 && idx < count) {
   "result : %s\n", stack[idx];
   return stack[idx];
 }

 return "";
}

U8 stack_pop()
{//Pop an item, off the stack.
 if (count > 0) {
   U8 *result = stack[count - 1];

   count--;

   "result : %s\n", result;
   return result;
 }

 return "";
}

U64 HashCodeFor(U8 *str) 
{//Hash code generator for strings.
  U64 hash = 0;
  U64 g = 31;
  U64 i;

  for (i=0; i < StrLen(str); i++) {
    hash = g * hash + str[i];
  }

  return hash;
}

U8 execute_cmd(U8 *cmd) {
  U64 at = token_count(cmd),
       i = 0,
       h = 0;

  for (i=0; i < at; i++) {
    token_trim(cmd,FALSE,TRUE);

    cmd = stack_push(cmd);
  }

  h = HashCodeFor(stack_peek(0));

  "Hash : %d\n", h;

  if (h == 3127582) { //exit
//    if (err_check) {
//      return 1;
//    }
  }
  else if (h == 98262) { //cat
//    if (err_check(2,2,,,,TRUE)) {
//      Type(tokens[1]);
//    }
  }
  else if (h == 3560141) { //time
//    if (err_check) {
//      "%T\n", Now;
//    }
  }
  else if (h == 3169 || h == 98339) { //cd & cdd
//    if (err_check(1,3,,,TRUE)) {
//      if (tc == 2) {
//        Cd(tokens[1]);
//      }
//      else {
//        Cd;
//      }

//      if (h == 98339) {
//        external("Dir;");
//      }
//    }
  }
  else if (h == 94746189) { //clear
//    if (err_check) {
//      DocClear;
//    }
  }
  else {
  }

  return FALSE;
}

U0 TempleDOS() {
  DocClear;

  "\n$FG,3$TempleDOS [Version 1.0]$FG$\n";
  "(c) 2022 No rights reserved. For Public Domain use.\n";
  "Type '$FG$$FG,2$help$FG$' for internal command list.\n\n$LK,"TempleOS commands",A="HI:Cmd Line (Typically)"$\n";

  U8 *input;
  U64 result = 0;

  while (1)
  {
    "\n%s: ", Fs->cur_dir; // Display prompt

    // Get user input
    input = token_trim(GetStr(,,GSF_SHIFT_ESC_EXIT), FALSE, TRUE);

    if (StrLen(input) > 0) {
      result = execute_cmd(input);
    }

    input = '\0';

    if (result) break;
  }
}

TempleDOS;


