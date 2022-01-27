/*Bool drv_valid(U8 *drv)
{//Valid mounted drive?
  CDrv *dv;
  CBlkDev *bd;

  I64 i,drv_let;

  drv = ToUpper(drv);

  for (i=0,dv=blkdev.drvs;i<DRVS_NUM;i++,dv++) {
    if (dv->dv_signature==DRV_SIGNATURE_VAL) {
      bd=dv->bd;
      drv_let=Drv2Let(dv);
      "%c\n",drv_let;
      if (drv_let == drv) {
        return TRUE;
      }
    }
  }

  return FALSE;
}

if (drv_valid('c')) {
  "yeppers\n";
}
else {
  "nope\n";
}

"DrvSerialNum %s\n",DrvSerialNum(Drv2Let(Fs->cur_dv));
*/

U0 _() {
 "hello\n";
}

_;