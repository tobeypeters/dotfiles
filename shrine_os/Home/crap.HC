U64 class CStrSplit{
    U64 *ToArray;
    I64 Length;
};

static CStrSplit StrSplit(U8 *str, U8 *f){
        //Splitting Whole Str into Multiple Str and Return Token with Str Contain
    CStrSplit CSS;

    U8 *s=NULL;
        I64 *IT=StrIAToken(str,f), l=StrDLen(str,f)+1;
        I64 a=0,b=0;

        CSS.ToArray=MAlloc(l*sizeof(U64));
        for(a=0;a<l-1;a++){
                while(b<IT[a]){
                        s=MStrPrint("%s%c",s,str[b]); //Patch Fixed!
                        b++;
                }
                b=StrLen(f)+IT[a];
                CSS.ToArray[a]=s;

                s=NULL;
        }
        while(b<StrLen(str)) {
                s=MStrPrint("%s%c",s,str[b]);
                b++;
        }
        CSS.ToArray[a]=s;
        CSS.Length=a;

        s=NULL;
        IT=NULL;

        return CSS;
}

U8 *str="Lorem ipsum ....;
U8 *old="dolor", *new="Hello Worlds!";

CStrSplit z=StrSplit(str,old);
"%d\n",z.Length;

I64 a;
for(a=0;a<z.Length;a++) "%s\n",z.ToArray[a];