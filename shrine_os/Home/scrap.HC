//"\n";
//
//drv_free;
//drv_free('C');
//"C free %7.2f%%\n",drv_free('C',TRUE);
//drv_free(,TRUE);
//
//"\n";

DocClear;

"\n";

/*"IsDir(): %d %d %d %d\n",'-','~',IsDir("/"),IsDir("~");
"FileFind(): %d %d %d %d\n",'-','~',FileFind('/'),FileFind("~");

//And before you say duh ... you CAN use FileFind on
//MOST directories in TempleOS.  Unless, you set the appropriate flag.
//Things can always be overrided.  This was his grep function.
//$LK,"FUF_JUST_DIRS",A="MN:FUF_JUST_DIRS"$, $LK,"FUF_JUST_FILES",A="MN:FUF_JUST_FILES"$, $LK,"FUF_Z_OR_NOT_Z",A="MN:FUF_Z_OR_NOT_Z"$, $LK,"FUF_SCAN_PARENTS",A="MN:FUF_SCAN_PARENTS"$
"FileFind(\"\Demo\"): %d\n",FileFind("/Demo");*/

//Watch this:
"%d %d\n",'a','z'; //97 .. 122 
"%d %d\n",*"a",*"z"; //97 .. 122 
"%d %d\n",*"a:",*"z:"; //97 .. 122 
"%d %d\n",*"a:/",*"z:/"; //97 .. 122 


"\n";

KeyAndCont;
Exit;
