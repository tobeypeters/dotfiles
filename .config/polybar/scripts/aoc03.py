#!/usr/bin/env python3

# Count the ones and zeroes in each column.
INPUT_S = '''\
00100
11110
10110
10111
10101
01111
00111
11100
10000
11001
00010
01010
'''

# Count of ones: [7, 5, 8, 7, 5]
# Build a new binary.
# More ones than zeros:
#                 1  0  1  1  0

lines = INPUT_S.splitlines()

counts = [0] * len(lines[0])

for line in lines:
    for i, c in enumerate(line):
        if c == '1':
            counts[i] += 1

gamma = 0
eps = 0

print(counts)

for i in range(len(lines[0])):
    gamma <<= 1
    eps <<= 1
    if counts[i] > len(lines) // 2:
        gamma += 1
    else:
        eps += 1

print(bin(gamma))
print(bin(eps))

print(gamma * eps)
