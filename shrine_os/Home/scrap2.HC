U8 *st[5][12];

U64 i=0,j=0,parts=5,lb=12
;
for (;i<parts;i++)
  for (;j<lb;j++)
    st[i][j]=CAlloc(lb);

"st:%d\n",sizeof(st);

