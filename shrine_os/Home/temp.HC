#include "~/td/errors"
#include "~/td/strings"

Bool flag_val(U8 *flags,U8 *chr)
{//Is chr present, in the the flags we got?
  flags=str_lower(flags);
  while (*flags) {
    if (*flags==chr) return TRUE;
    flags++;
  }
  return FALSE;  
}
U64 flag_cnt(U8 *flags)
{//Get the number of provided flags.
  return StrLen(flags)-(*flags=='-');
}
Bool flag_err(U8 *flags=NULL, I64 flag_want,Bool print_err=TRUE,U8 *help_file=NULL,U8 *cmd=NULL)
{//Validate the provied flag. If it's not potentially print an error message.
  if (flag_val(flag_want,flags)) return TRUE;
  if (print_err) err_print(ERR_FLGI,,help_file,cmd);
  return FALSE;
}
