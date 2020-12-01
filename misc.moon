
export between = (a, b, c, mod) ->
  -- a, b, c being scalar values
  print a,b,c,mod if a~=a or b~=b or c~=c
  -- c += mod if b > 0 and c <= 0
  -- a += mod if b > 0 and b > 0 and c <= 0
  a += mod
  b += mod
  c += mod
  return b < a and a < c
  -- if mod == nil or b < c
  --   (b < a) and (c > a)
  -- else
  --   (b < a + mod) and (c > a)

export rotary_shift = (table, zero_index) ->
  shifted = {}
  -- zero_index = -1
  -- for i = 1, #table
  --   zero_index = i if table[i] == zero
  for i = zero_index, #table
    shifted[#shifted + 1] = table[i]
  for i = 1, zero_index - 1
    shifted[#shifted + 1] = table[i]

  return shifted

print "#{between(1, 0.18, -1.8, math.pi*2)}"

table = {
  1
  2
  3
  4
  5
  6
}
shifted = rotary_shift(table, 4)
for i in *table
  print i
for i in *shifted
  print i
