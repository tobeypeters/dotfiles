Bool str_cmp(U8 *stra, U8 *strb, Bool ignore_case=FALSE)
{//StrCmp replacement which returns TRUE & FALSE.
 //Saying !StrCmp() for TRUE, erks me ...
  Bool result = FALSE;

  if (ignore_case) {
    result = (!(StrICmp(stra,strb)));
  }
  else { 
    result = (!(StrCmp(stra,strb)));
  }

  return result;
}


U8 *arr[1][7]={{123, "clear", 1, 2, FALSE, 3, 4}};

"\n";
"%d\n",arr[0][0];
"%s\n",arr[0][1];
"%d\n",arr[0][2];
"%d\n",arr[0][3];
"%d\n",arr[0][4];
"%d\n",arr[0][5];
"%d\n",arr[0][6];

U8 arr2[1][7];

arr2[0][0]=123;
arr2[0][1]="clear";
arr2[0][2]=1;
arr2[0][3]=2;
arr2[0][4]=FALSE;
arr2[0][5]=3;
arr2[0][6]=4;

"\n";
"%d\n",arr[0][0];
"%s\n",arr[0][1];
"%d\n",arr[0][2];
"%d\n",arr[0][3];
"%d\n",arr[0][4];
"%d\n",arr[0][5];
"%d\n",arr[0][6];
"\n";

