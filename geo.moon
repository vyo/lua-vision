#!/usr/bin/env moon

-- angle in radians
-- rotating clockwise
export rotate = (vector, angle) ->
  alpha = pseudo_angle(vector)
  {x:math.cos(alpha - angle),y:math.sin(alpha - angle)}

-- get the pseudo_angle value for this vector
-- values from -2 to +2
-- +2 is left/270 degrees, down to -2, going clockwise
export pseudo_angle = (vector) ->
  -- return 0 if vector == nil or vector.x == nil or vector.y == nil
  -- print "rotating vector #{vector}"
  -- print "#{vector.x}"
  -- print "#{vector.y}"
  r = vector.x / (math.abs(vector.x) + math.abs(vector.y))
  if vector.y < 0
    return r - 1
  else
    return 1 - r
  print r

-- indicates whether direction vector b is smaller/left/counterclockwise
-- relative to vector a, or equal or greater/right/clockwise to it
-- basically checks whether vector b is in the left or right half-circle
-- of the circle defined by vector a pointing up/12 o'clock
-- kinda sorta
export angle_compare = (vec_a, vec_b) ->
  -- chicken out early
  return 0 if vec_a == nil or vec_b == nil
  -- get the pseudo_angles
  -- map them from [-2,+2] to [0,4]
  angle_a = pseudo_angle(vec_a) + 2
  angle_b = pseudo_angle(vec_b) + 2
  return 0 if angle_a == angle_b
  -- transform the problem into the easiest case: vector a points directly right
  -- that way the discontinuity is at 180 degrees/directly behind and need not
  -- be considered explicitly
  diff = 4 - angle_a
  angle_a += diff+2
  angle_b += diff+2
  angle_a %= 4
  angle_b %= 4

  return -1 if angle_b >= 2
  return 1 if angle_b <= 2

export sort_by_angle = (origin, vectors) ->
  -- map angles to a [0,4] range
  -- precompute offset to the zero position
  diff = 4 - (pseudo_angle(origin)+2)
  table.sort(vectors, (vec_a, vec_b) -> (pseudo_angle(vec_a)+diff)%4 > (pseudo_angle(vec_b)+diff)%4)
  table.remove(vectors,#vectors)
  table.insert(vectors,1,origin)

up = {x:0,y:1}
up_right = {x:1,y:1}
right = {x:1,y:0}
down_right = {x:1,y:-1}
down = {x:0,y:-1}
down_left = {x:-1,y:-1}
left = {x:-1,y:0}
up_left = {x:-1,y:1}

directions = {
  up
  up_right
  right
  down_right
  down
  down_left
  left
  up_left
}

print pseudo_angle(up)+2
print pseudo_angle(up_right)+2
print pseudo_angle(right)+2
print pseudo_angle(down_right)+2
print pseudo_angle(down)+2
print pseudo_angle(down_left)+2
print pseudo_angle(left)+2
print pseudo_angle(up_left)+2

print angle_compare(up, up_right)
print angle_compare(up, up_left)
print angle_compare(left, up_left)
print angle_compare(left, down_left)

sort_by_angle(right, directions)
print "#{vec.x} | #{vec.y}" for vec in *directions

downish = rotate(right, math.rad(90))
print "#{downish.x} | #{downish.y}"
upish = rotate(right, math.rad(-90))
print "#{upish.x} | #{upish.y}"

