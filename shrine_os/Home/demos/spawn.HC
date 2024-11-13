U0 func()
{
  U64 i=0;
  for(;i<10000;i++) { }
}

CTask *stask;

U64 cc=Max(0,mp_cnt-1);
Adam("\"%d\n\";",cc); //always works.  My case gives me 3(4 cores)

Fs->animate_task=Spawn(&func,NULL,"func_task",cc,Fs);
