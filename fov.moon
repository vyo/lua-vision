#!/usr/bin/env moon

require 'misc'

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
  screen_x, screen_y = love.graphics.getDimensions()
  print "\n"
  print "all lines: "..#lines.." lines"
  for line in *lines
    print "line: #{line.a.x}/#{line.a.y}"
    -- set up all the light rays we'll be casting out
    -- each line end point is a start as well as an end -
    -- don't use them twice!
    -- todo: use proper angles...
    rays[#rays + 1] = {a: origin, b: line.a}
    print "ray from: #{rays[#rays].a.x}/#{rays[#rays].a.y}"
    print "to: #{rays[#rays].b.x}/#{rays[#rays].b.y}"
    print "angle: #{pseudo_angle({x:rays[#rays].b.x-rays[#rays].a.x, y:rays[#rays].b.y-rays[#rays].a.y})}"
    rays[#rays + 1] = {a: origin, b: {x: clamp(line.a.x + 0.001, 0, screen_x), y: clamp(line.a.y + 0.001, 0, screen_y)}}
    rays[#rays + 1] = {a: origin, b: {x: clamp(line.a.x - 0.001, 0, screen_x), y: clamp(line.a.y - 0.001, 0, screen_y)}}
    print "ray count: "..#rays
  
  if segment ~= nil
    -- todo: this 'between' filter drops too much
    -- visible_rays = {}
    -- for ray in *rays
    --   print "possibly visible ray: #{pseudo_angle({x:ray.b.x-ray.a.x, y:ray.b.y-ray.a.y})}"
    --   if between(pseudo_angle({x:ray.b.x-ray.a.x, y:ray.b.y-ray.a.y}), pseudo_angle(segment.a), pseudo_angle(segment.b), math.pi*2)
    --     print "between "..pseudo_angle(segment.a).." and "..pseudo_angle(segment.b)
    --     visible_rays[#visible_rays + 1] = ray
    --   else
    --     print "not between "..pseudo_angle(segment.a).." and "..pseudo_angle(segment.b)
    -- rays = visible_rays
    rays = [ ray for ray in *rays when between_angles({x:ray.b.x-ray.a.x, y:ray.b.y-ray.a.y}, segment.a, segment.b, math.pi*2) ]
    rays[#rays + 1] = {a: origin, b: {x:segment.a.x+origin.x,y:segment.a.y+origin.y}}--segment.a}
    rays[#rays + 1] = {a: origin, b: {x:segment.b.x+origin.x,y:segment.b.y+origin.y}}--segment.b}
  print "\n"
  print "all rays: "..#rays.." rays"
  -- todo: already too few rays when we get here =/
  for ray in *rays
    print "ray: #{pseudo_angle({x:ray.b.x-ray.a.x, y:ray.b.y-ray.a.y})}"
    print "ray (relative): #{pseudo_angle(ray.b)}"
    print "position: #{ray.b.x}/#{ray.b.y}"
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
      -- intersections[#intersections + 1] = intersection_far if intersection_far ~= nil
    -- only take the closest intersection => culling
    sort_by_distance(origin, intersections)
    visible_area[#visible_area + 1] = intersections[1] if #intersections > 0
    print "intersections: #{#intersections}"
    intersections = {}
 
  -- if segment ~= nil
    -- if our field of vision is a circular segment instead of a full circle
    -- we have to add our origin as one of the field-of-view vertices
   -- todo: add last, after everything is done
    -- visible_area[#visible_area + 1] = origin
  print "#{origin}"
  print "#{visible_area}"
  -- sort_by_angle(origin, visible_area)
  sort_by_angle(segment.a, visible_area)
   
  -- and now, let's have some post-processing:
  processed = {}
  -- drop all points whose relative angle or coordinates are too
  -- close to the previous point's
  -- compare successive points and update point of reference
  reference = visible_area[#visible_area]
  for i=1,#visible_area
    -- todo: both of the following criteria don't remove too many rays?
    -- processed[#processed + 1] = visible_area[i]
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
      print "closest index: #{i}"
      closest_index = i
      closest_distance = distance

  -- sort_by_angle(origin, processed)
  sort_by_angle(segment.a, processed)
  -- processed = rotary_shift(processed, closest_index)
  -- if segment ~= nil
    -- if our field of vision is a circular segment instead of a full circle
    -- we have to add our origin as one of the field-of-view vertices
   -- todo: add last, after everything is done
    -- processed[#processed + 1] = origin
  print #processed
  print closest_index
  -- print processed[closest_index].x
  -- print processed[closest_index].y
  -- print segment.a.x
  -- print segment.a.y
  print "leftmost ray: #{pseudo_angle(segment.a)}"
  -- print "chosen ray: #{pseudo_angle(processed[1])}"
  print "chosen ray: #{pseudo_angle({x:processed[1].x-origin.x, y:processed[1].y-origin.y})}"
  print "rightmost ray: #{pseudo_angle(segment.b)}"
  print ""
  print "visible area: "..#visible_area.." rays"
  for ray in *visible_area
    print "ray: #{pseudo_angle({x:ray.x-origin.x, y:ray.y-origin.y})}"
    print "position: #{ray.x}/#{ray.y}"
  print ""
  print "unused rays: "..#rays.." rays"
  for ray in *rays
    print "ray: #{pseudo_angle({x:ray.b.x-origin.x, y:ray.b.y-origin.y})}"
  print ""
  print "used rays: "..#processed.." rays"
  for ray in *processed
    -- print "ray: #{pseudo_angle(ray)}"
    print "ray: #{pseudo_angle({x:ray.x-origin.x, y:ray.y-origin.y})}"
    print "position: #{ray.x}/#{ray.y}"
  print "\n"
  print "end of step\n\n"
  return processed

