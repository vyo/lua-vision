require 'geo'
require 'misc'

offset_counterclockwise = math.rad(-0.1)
offset_clockwise = math.rad(0.1)

export visibility_poly = (origin_point, origin_angle, blockers, fov) ->
  -- with
  -- origin: being a point {:x, :y} and an angle
  -- blockers: being a list of polygons
  -- fov: being an angle, in radians
  
  segment = {
    -- a: {x:origin_point.x + 100*math.cos(-fov/2), y:origin_point.y + 100*math.sin(-fov/2)}
    -- b: {x:origin_point.x + 100*math.cos(fov/2), y:origin_point.y + 100*math.sin(fov/2)}
    a: rotate(state.view_angle_vector, -fov/2)
    b: rotate(state.view_angle_vector, fov/2)
  }
  print 'visibility polygon:'
  print "fov: #{fov}"
  print "a angle: #{pseudo_angle(segment.a)}"
  print "b angle: #{pseudo_angle(segment.b)}"
  visible_area = {}
  rays = {}
  lines = flatten([ to_lines(poly) for poly in *blockers ])
  screen_x, screen_y = love.graphics.getDimensions()
  print "\n"
  print "all lines: "..#lines.." lines"
  for line in *lines
    print "line: #{line.a.x}/#{line.a.y}"
    -- set up all the light rays we'll be casting out
    -- each line end point is a start as well as an end -
    -- don't use them twice!
    -- also, send out an additional ray slightly offset to either
    -- side, so we don't get blocked by the corners of a polygon
    rays[#rays + 1] = {a: origin_point, b: line.a}
    -- todo: whooopsies, we try to rotate lines here lol
    print "#{origin_point.x} | #{origin_point.y}"
    line_vector = {x:line.a.x-origin_point.x,y:line.a.y-origin_point.y}
    counterclockwise_vector = rotate(line_vector, offset_counterclockwise)
    clockwise_vector = rotate(line_vector, offset_counterclockwise)
    print "line vector: #{line_vector.x}/#{line_vector.y}"
    print "counterclockwise vector: #{counterclockwise_vector.x}/#{counterclockwise_vector.y}"
    print "clockwise vector: #{clockwise_vector.x}/#{clockwise_vector.y}"
    rays[#rays + 1] = {a: origin_point, b: {x:line.a.x+counterclockwise_vector.x,y:line.a.y+counterclockwise_vector.y}}
    rays[#rays + 1] = {a: origin_point, b: {x:line.a.x+clockwise_vector.x,y:line.a.y+clockwise_vector.y}}
    print "ray from: #{rays[#rays].a.x}/#{rays[#rays].a.y}"
    print "to: #{rays[#rays].b.x}/#{rays[#rays].b.y}"
    print "angle: #{pseudo_angle({x:rays[#rays].b.x-rays[#rays].a.x, y:rays[#rays].b.y-rays[#rays].a.y})}"
  print "ray count (original): "..#rays
  -- if fov ~= nil
    -- rays = [ ray for ray in *rays when between_angles(segment.a, segment.b, {x:ray.b.x-ray.a.x, y:ray.b.y-ray.a.y}) ]
  print "ray count (culled): "..#rays
  -- drop duplicates
  culled = {}
  for ray in *rays
    if not contains(culled, ray, (a,b) -> (a.b.x == b.b.x and a.b.y == b.b.y))
      culled[#culled + 1] = ray
  rays = culled
  print "ray count (pruned): "..#rays

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
      -- intersection_far = intersection(ray, line, false)
      if intersection_near ~= nil
        intersection_near.a = ray.a
        intersection_near.b = ray.b
      -- if intersection_far ~= nil
        -- intersection_far.a = ray.a
        -- intersection_far.b = ray.b
      intersections[#intersections + 1] = intersection_near if intersection_near ~= nil
      -- intersections[#intersections + 1] = intersection_far if intersection_far ~= nil
    -- only take the closest intersection => culling
    sort_by_distance(origin_point, intersections)
    visible_area[#visible_area + 1] = intersections[1] if #intersections > 0
    print "intersections: #{#intersections}"
    intersections = {}
 
  -- if segment ~= nil
    -- if our field of vision is a circular segment instead of a full circle
    -- we have to add our origin as one of the field-of-view vertices
   -- todo: add last, after everything is done
    -- visible_area[#visible_area + 1] = origin
  print "#{origin_point}"
  print "#{visible_area}"
  -- sort_by_angle(origin, visible_area)
  sort_by_angle(segment.a, visible_area)
   
  -- and now, let's have some post-processing:
  -- TODO: also, this doesn't do shit
  processed = {}
  -- drop all points whose relative angle or coordinates are too
  -- close to the previous point's
  -- compare successive points and update point of reference
  reference = visible_area[#visible_area]
  for i=1,#visible_area
    -- todo: both of the following criteria don't remove too many rays?
    -- processed[#processed + 1] = visible_area[i]
    if manhattan_distance(visible_area[i], reference) > 2 and pseudo_angle({x:visible_area[i].x - origin_point.x, y:visible_area[i].y - origin_point.y}) ~= pseudo_angle({x:reference.x - origin_point.x, y:reference.y - origin_point.y})
      processed[#processed + 1] = visible_area[i]
      reference = visible_area[i]
  closest_index = 1
  closest_distance = math.huge
  for i = 1, #processed
    distance = math.abs(math.abs(pseudo_angle(segment.a)) - math.abs(pseudo_angle({x:processed[i].x-origin_point.x, y:processed[i].y-origin_point.y})))
    -- distance = (pseudo_angle(segment.a)^2 - pseudo_angle(processed[i])^2)^2
    if distance == distance and distance < closest_distance
      print "distance: #{distance}"
      print "closest index: #{i}"
      closest_index = i
      closest_distance = distance

  processed = visible_area
  -- sort_by_angle(origin_point, processed)
  sort_by_angle(segment.a, processed)
  -- processed = rotary_shift(processed, closest_index)
  -- if segment ~= nil
    -- if our field of vision is a circular segment instead of a full circle
    -- we have to add our origin as one of the field-of-view vertices
   -- todo: add last, after everything is done
   -- todo: really needed?
    -- processed[#processed + 1] = origin
  print #processed
  print closest_index
  -- print processed[closest_index].x
  -- print processed[closest_index].y
  -- print segment.a.x
  -- print segment.a.y
  print "leftmost ray: #{pseudo_angle(segment.a)}"
  -- print "chosen ray: #{pseudo_angle(processed[1])}"
  print "chosen ray: #{pseudo_angle({x:processed[1].x-origin_point.x, y:processed[1].y-origin_point.y})}"
  print "rightmost ray: #{pseudo_angle(segment.b)}"
  print ""
  print "visible area: "..#visible_area.." rays"
  for ray in *visible_area
    print "ray: #{pseudo_angle({x:ray.x-origin_point.x, y:ray.y-origin_point.y})}"
    print "position: #{ray.x}/#{ray.y}"
  print ""
  print "unused rays: "..#rays.." rays"
  for ray in *rays
    print "ray: #{pseudo_angle({x:ray.b.x-origin_point.x, y:ray.b.y-origin_point.y})}"
  print ""
  print "used rays: "..#processed.." rays"
  for ray in *processed
    -- print "ray: #{pseudo_angle(ray)}"
    print "ray: #{pseudo_angle({x:ray.x-origin_point.x, y:ray.y-origin_point.y})}"
    print "position: #{ray.x}/#{ray.y}"
  print "\n"
  print "end of step\n\n"
  return processed

