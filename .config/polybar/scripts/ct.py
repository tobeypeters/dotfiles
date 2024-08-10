#!/usr/bin/env python3

windows: list[int]= [1,2,3,4,5]
wid=5
wc = len(windows)
fi = 4
bc = 1

fi=((windows.index(wid) if wid in windows else 0) + (1 if bc == 1 else -1)) % wc
print(f'{fi}')
#fi=((windows.index(fi) if fi in windows else 0) + (1 if bc == 1 else -1)) % wc

#print(f'{windows[fi]}')