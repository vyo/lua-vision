require 'geo'

export contains = (table, element, comparison) ->
  for item in *table
    return true if comparison(element, item)
  return false

export copy = (table) ->
  tmp = {}
  for k,v in pairs(table)
    tmp[k] = if type(v) == 'table' then copy(v) else v
  return tmp

export is_parallel = (a, b) ->
  -- a, b being directions of the form {:x, :y}
  a.x/a.y == b.x/b.y

export to_direction = (a, b) ->
  -- a, b being points of the form {:x, :y}
  {x: b.x-a.x, y: b.y-a.y}
export intersection = (a, b, include_endpoints = false) ->
  pA = a.a
  pB = b.a

  dA = to_direction(a.a, a.b)
  dB = to_direction(b.a, b.b)
  
  lengthB = (dA.x*(pB.y - pA.y) + dA.y*(pA.x - pB.x))/(dB.x*dA.y - dB.y*dA.x)
  lengthA = (pB.x + dB.x*lengthB - pA.x)/dA.x
  
  if (lengthA > 0 and lengthB > 0 and lengthB < 1) or (include_endpoints and (lengthA >= 0 and lengthB >= 0 and lengthB <= 1))
    {
      x: pA.x + dA.x*lengthA
      y: pA.y + dA.y*lengthA
    }

export wrap = (element) -> if type(element) == 'table' return element else return {element}
export flatten = (list) ->
  -- print it for it in *list
  flat_list = {}
  for element in *list
    if type(element ) == 'table' and #element == 0
      continue
    for nested in *wrap(element)
      flat_list[#flat_list + 1] = nested
  return flat_list

export to_poly = (lines) ->
  -- returns a list of points {:x, :y}
  -- we only need the starting point (or endpoint) of
  -- every line segment to fully describe the polygon
  [ line.a for line in *lines ]

export to_lines = (poly) ->
  -- a poly is just a list of values
  lines = {}
  for i = 1, #poly - 1
    lines[#lines + 1] = { a: poly[i], b: poly[i + 1]}
  -- wrap around to close the polygon
  lines[#lines + 1] = { a: poly[#poly], b: poly[1] }
  return lines
  -- return [{x:line[1], y:line[2]} for line in *lines]

export manhattan_distance = (a, b) -> 
  math.abs(b.x-a.x) + math.abs(b.y-a.y)
export to_raw_coordinates = (poly) ->
  flatten([ {poly[i].x, poly[i].y} for i=1,#poly ])

export sign = (number) -> if number < 0 then -1 else 1
export copysign = (x, y) ->
  -- use the magnitude of :x, and the sign of :y
  math.abs(x) * sign(y)
export angle = (v) -> math.atan(v.y, v.x)
-- todo: which one?
-- export pseudo_angle = (v) -> copysign(1 - v.x/(math.abs(v.x) + math.abs(v.y)), v.y)
-- export pseudo_angle = (v) ->
  -- expects a vector v = {x, y}
  -- angle(v)
export pseudo_angle2 = (v) ->
  angle = copysign(1 - (v.x+0.00000001)/((math.abs(v.x) + math.abs(v.y) + 0.00000001)), v.y)
  print "not an angle: #{v.x}/#{v.y}, phi: #{angle}" if angle ~= angle
  angle = 0 if angle ~= angle
  angle
export compare_angle = (a, b) ->
  angle = math.atan(a.y, a.x) < math.atan(b.y, b.x)
  -- print angle, "#{a.x}/#{a.y}", "#{b.x}/#{b.y}"
  angle
export compare_pseudo_angle = (a, b) ->
  -- return orientation(a, b)
  print "a: #{a}"
  print "b: #{b}"
  if a == nil or b == nil
    print "result: #{nil}"
    return nil
  phi_a = pseudo_angle(a)
  phi_b = pseudo_angle(b)
  print "#phi_a: #{phi_a}"
  print "#phi_b: #{phi_b}"
  result = nil
  if (phi_a < 0 and phi_b < 0)
    result = (phi_a < phi_b)
  else
    result = (phi_a > phi_b)
  print "result: #{result}"
  result

-- export sort_by_angle = (origin, lines) ->
--   table.sort(lines, (a, b) -> orientation({x:a.x - origin.x, y:a.y - origin.y}, {x:b.x - origin.x, y:b.y - origin.y}))
export sort_by_distance = (origin, points) ->
  table.sort(points, (a, b) -> (a.x-origin.x)^2 + (a.y-origin.y)^2 < (b.x-origin.x)^2 + (b.y-origin.y)^2)

export between_angles = (c, a, b) ->
  return angle_compare(a,c) <= -1 and angle_compare(b,c) >= 1
  -- return orientation(a, c) and orientation(b, c)
  -- return compare_pseudo_angle(a, c) and compare_pseudo_angle(c, b)
  -- if (a <= b)
  --   return (a <= c) and (c <= b)
  -- else
  --   return (c <= a) and (b <= c)

export between = (c, a, b, mod) ->
  -- return compare_pseudo_angle(a, c) and compare_pseudo_angle(c, b)
  if (a <= b)
    return (a <= c) and (c <= b)
  else
    return (c <= a) and (b <= c)

export between_old = (a, b, c, mod) ->
  -- a, b, c being scalar values
  print a,b,c,mod if a~=a or b~=b or c~=c
  -- c += mod if b > 0 and c <= 0
  -- a += mod if b > 0 and b > 0 and c <= 0
  a += mod
  b += mod
  c += mod
  return b <= a and a <= c
  -- return c <= b and a <= c
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

export clamp = (value, min, max) ->
  if value < min
    return min
  else
    if value > max
      return max
    else
      return value

export orientation = (a, b) -> 
  if a == nil or b == nil
    return true
  phi_a = pseudo_angle(a)
  phi_b = pseudo_angle(b)
  diff = phi_b - phi_a
  -- is b closer to the right of a than to the left of a?
  -- also: and a**2 + b**2 < 4
  return (diff <= 0 and diff >= -2) or diff > 2

print "clamp -0.0001, 0, 480): #{clamp(-0.0001, 0, 480)}"

print "#{between(1, 0.18, -1.8, math.pi*2)}"
print "#{between(1.1789536821258, -1.8210462926645, -1.4103582085703, math.pi)}"

print "angles:"
angles = {
  {x: 0 , y: 1},
  {x: 1 , y: 1}
  {x: 1 , y: 0}
  {x: 1 , y: -1}
  {x: 0 , y: -1}
  {x: -1 , y: -1}
  {x: -1 , y: 0}
  {x: -1 , y: 1}
  {x: 0 , y: 1},
}

print "done comparing angles =)"
print "forward"
for i=1, #angles-1
  print("a: #{pseudo_angle(angles[i])}")
  print("b: #{pseudo_angle(angles[i+1])}")
  print("#{orientation(angles[i], angles[i + 1])}")
  print "\n"

print "backward"
for i=1, #angles-1
  print("a: #{pseudo_angle(angles[i+1])}")
  print("b: #{pseudo_angle(angles[i])}")
  print("#{orientation(angles[i+1], angles[i])}")
  print "\n"

print "done comparing angles =)"

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
