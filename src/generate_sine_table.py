import math

C = 100
A = 40
N = 320
PER_LINE = 16

values = [
    round(C + A * math.sin(2 * math.pi * i / N))
    for i in range(N)
]

print("sin_y_table:")
for i in range(0, N, PER_LINE):
    row = values[i:i+PER_LINE]
    print("    db " + ", ".join(str(v) for v in row))

