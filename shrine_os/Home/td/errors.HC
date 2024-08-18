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

/*errors.HC
  Description:
      Error message definitions and print routine.
*/

#define ERR_ARGTC       "Too many arguments provided"
#define ERR_ARGC        "Too few or too many arguments provided"
#define ERR_FLGC        "Too few or too many options provided"
#define ERR_FLGI        "Invalid option provided"
#define ERR_FILEI       "Invalid filename"

#define ERR_NF          "Not found"

#define ERR_DRVIU       "Invalid or unmounted drive"

#define ERR_DRV_SPEC    "Drive was specified"
#define ERR_DIR_SPEC    "Directory was specified"
#define ERR_FILE_SPEC   "File was specified"

#define ERR_DIR_EXISTS  "Directory already exists"
#define ERR_FILE_EXISTS "File already exists"
#define ERR_FILE_EX_DIR "Existing file was specified instead of a non existing directory"

#define ERR_DIRFILEIDRV "Directory or file provided instead of a drv"
#define ERR_DRVFILEIDIR "Drive or file provided instead of a directory"
#define ERR_DRVDIRIFILE "Drive or directory provided instead of a file"
#define ERR_DRVIDIRFILE "Drive provided instead of a directory or file"
#define ERR_FILEIDRVDIR "File provided instead of a drv or directory"

#define ERR_UNKNOWN     "Unrecognized command provided"

U0 err_print(U8 *msg,U8 *link="Usage",U8 *help_file=NULL,U8 *cmd=NULL)
{//Print our err_msg.
//$$LK+PU,"Usage",A="FF:~/td/templeDOS.DD,cp"$$
  U8 *err_link;

  if (!StrCmp(link,"Usage")) err_link=MStrPrint("$$LK+PU,\"%s\",A=\"FF:%s,_%s\"$$",link,help_file,cmd);
  else err_link=StrNew(link);

  "`%s`: %s ...\n",err_link,msg;
  Free(err_link);
}
