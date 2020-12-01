#!/usr/bin/env moon

require 'misc'

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
  lines = {}
  for i = 1, #poly - 1
    lines[#lines + 1] = { a: poly[i], b: poly[i + 1]}
  -- wrap around to close the polygon
  lines[#lines + 1] = { a: poly[#poly], b: poly[1] }
  return lines

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
export pseudo_angle = (v) ->
  angle = copysign(1 - (v.x+0.00000001)/((math.abs(v.x) + math.abs(v.y) + 0.00000001)), v.y)
  print "not an angle: #{v.x}/#{v.y}, phi: #{angle}" if angle ~= angle
  angle = 0 if angle ~= angle
  angle
export compare_angle = (a, b) ->
  angle = math.atan(a.y, a.x) < math.atan(b.y, b.x)
  -- print angle, "#{a.x}/#{a.y}", "#{b.x}/#{b.y}"
  angle
export compare_pseudo_angle = (a, b) ->
  pseudo_angle(a) < pseudo_angle(b)
  -- copysign(1 - a.x/(math.abs(a.x) + math.abs(a.y)), a.y) < copysign(1 - b.x/(math.abs(b.x) + math.abs(b.y)), b.y)
export sort_by_angle = (origin, lines) ->
  table.sort(lines, (a, b) -> compare_pseudo_angle({x:a.x - origin.x, y:a.y - origin.y}, {x:b.x - origin.x, y:b.y - origin.y}))
export sort_by_distance = (origin, points) ->
  table.sort(points, (a, b) -> (a.x-origin.x)^2 + (a.y-origin.y)^2 < (b.x-origin.x)^2 + (b.y-origin.y)^2)

export visibility_poly = (origin, polies, view_segment) ->
  -- with
  -- origin: being a point {:x, :y}
  -- polies: being a list of polygons
  -- segment: being a circular segment {a: angle, b: angle}
  segment = copy(view_segment)
  print "a: #{pseudo_angle(segment.a)}"
  print "b: #{pseudo_angle(segment.b)}"
  visible_area = {}
  rays = {}
  lines = flatten([ to_lines(poly) for poly in *polies ])
  for line in *lines
    -- set up all the light rays we'll be casting out
    -- each line end point is a start as well as an end -
    -- don't use them twice!
    -- todo: use proper angles...
    rays[#rays + 1] = {a: origin, b: line.a}
    rays[#rays + 1] = {a: origin, b: {x: line.a.x + 0.001, y: line.a.y + 0.001}}
    rays[#rays + 1] = {a: origin, b: {x: line.a.x - 0.001, y: line.a.y - 0.001}}
 
  print "all rays:"
  for ray in *rays
    print "ray: #{pseudo_angle({x:ray.b.x-ray.a.x, y:ray.b.y-ray.a.y})}"
    print "ray (relativ): #{pseudo_angle(ray.b)}"
    print "position: #{ray.b.x}/#{ray.b.y}"
  if segment ~= nil
    rays = [ ray for ray in *rays when between(pseudo_angle({x:ray.b.x-ray.a.x, y:ray.b.y-ray.a.y}), pseudo_angle(segment.a), pseudo_angle(segment.b), math.pi*2) ]
    rays[#rays + 1] = {a: origin, b: {x:segment.a.x+origin.x,y:segment.a.y+origin.y}}--segment.a}
    rays[#rays + 1] = {a: origin, b: {x:segment.b.x+origin.x,y:segment.b.y+origin.y}}--segment.b}
  for ray in *rays
    intersections = {}
    for line in *lines
      intersection_near = intersection(ray, line, true)
      intersection_far = intersection(ray, line, false)
      if intersection_near ~= nil
        intersection_near.a = ray.a
        intersection_near.b = ray.b
      if intersection_far ~= nil
        intersection_far.a = ray.a
        intersection_far.b = ray.b
      intersections[#intersections + 1] = intersection_near if intersection_near ~= nil
    sort_by_distance(origin, intersections)
    visible_area[#visible_area + 1] = intersections[1] if #intersections > 0
    intersections = {}
 
  -- if segment ~= nil
    -- if our field of vision is a circular segment instead of a full circle
    -- we have to add our origin as one of the field-of-view vertices
   -- todo: add last, after everything is done
    -- visible_area[#visible_area + 1] = origin
  sort_by_angle(origin, visible_area)
   
  -- and now, let's have some post-processing:
  processed = {}
  -- drop all points whose relative angle or coordinates are too
  -- close to the previous point's
  -- compare successive points and update point of reference
  reference = visible_area[#visible_area]
  for i=1,#visible_area
    if manhattan_distance(visible_area[i], reference) > 2 and pseudo_angle({x:visible_area[i].x - origin.x, y:visible_area[i].y - origin.y}) ~= pseudo_angle({x:reference.x - origin.x, y:reference.y - origin.y})
      processed[#processed + 1] = visible_area[i]
      reference = visible_area[i]
  closest_index = 1
  closest_distance = math.huge
  for i = 1, #processed
    distance = math.abs(math.abs(pseudo_angle(segment.a)) - math.abs(pseudo_angle({x:processed[i].x-origin.x, y:processed[i].y-origin.y})))
    -- distance = (pseudo_angle(segment.a)^2 - pseudo_angle(processed[i])^2)^2
    if distance == distance and distance < closest_distance
      print "distance: #{distance}"
      closest_index = i
      closest_distance = distance

  processed = rotary_shift(processed, closest_index)
  if segment ~= nil
    -- if our field of vision is a circular segment instead of a full circle
    -- we have to add our origin as one of the field-of-view vertices
   -- todo: add last, after everything is done
    processed[#processed + 1] = origin
  print #processed
  print closest_index
  -- print processed[closest_index].x
  -- print processed[closest_index].y
  -- print segment.a.x
  -- print segment.a.y
  print "leftmost ray: #{pseudo_angle(segment.a)}"
  -- print "chosen ray: #{pseudo_angle(processed[1])}"
  print "chosen ray: #{pseudo_angle({x:processed[1].x-origin.x, y:processed[1].y-origin.y})}"
  print "visible area:"
  for ray in *visible_area
    print "ray: #{pseudo_angle({x:ray.x-origin.x, y:ray.y-origin.y})}"
    print "position: #{ray.x}/#{ray.y}"
  print "filtered rays:"
  for ray in *rays
    print "ray: #{pseudo_angle({x:ray.b.x-origin.x, y:ray.b.y-origin.y})}"
  print "pruned rays:"
  for ray in *processed
    -- print "ray: #{pseudo_angle(ray)}"
    print "ray: #{pseudo_angle({x:ray.x-origin.x, y:ray.y-origin.y})}"
    print "position: #{ray.x}/#{ray.y}"
  return processed

