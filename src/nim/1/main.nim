var sum = 0

for i in 1 ..< 1000:
  if i mod 3 == 0 or i mod 5 == 0:
    sum += i

echo sum
