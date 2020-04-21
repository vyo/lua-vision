#!/usr/bin/env moon

screen_x, screen_y = love.graphics.getDimensions()

canvas = {
  -- screen borders
  { a: {x: 0, y: 0}, b: {x: screen_x, y: 0} }
  { a: {x: screen_x, y: 0}, b: {x: screen_x, y: screen_y} }
  { a: {x: screen_x, y: screen_y}, b: {x: 0, y: screen_y} }
  { a: {x: 0, y: screen_y}, b: {x: 0, y: 0} }
}

for line in *canvas
  print line

copy = (table) ->
  tmp = {}
  for k,v in pairs(table)
    tmp[k] = if type(v) == 'table' then copy(v) else v
  return tmp

is_parallel = (a, b) ->
  -- a, b being directions of the form {:x, :y}
  a.x/a.y == b.x/b.y

to_direction = (a, b) ->
  -- a, b being points of the form {:x, :y}
  {x: b.x-a.x, y: b.y-a.y}
intersection = (a, b, include_endpoints = false) ->
  pA = a.a
  pB = b.a
  dA = to_direction(a.a, a.b)
  dB = to_direction(b.a, b.b)
  lengthB = (dA.x*(pB.y - pA.y) + dA.y*(pA.x - pB.x))/(dB.x*dA.y - dB.y*dA.x)
  lengthA = (pB.x + dB.x*lengthB - pA.x)/dA.x
  -- print "#{dA.x}/#{dA.y}"
  -- print "#{dB.x}/#{dB.y}"
  -- print lengthA
  -- print lengthB
  if (lengthA > 0 and lengthB > 0 and lengthB < 1) or (include_endpoints and (lengthA >= 0 and lengthB >= 0 and lengthB <= 1))
  -- if (lengthA > 0 and lengthB > 0 and lengthB < 1) or (include_endpoints and (lengthA >= 0 and lengthB >= 0))
    {
      x: pA.x + dA.x*lengthA
      y: pA.y + dA.y*lengthA
    }

d = to_direction({x: 2, y: 5}, {x: 5, y: 15})
print "#{d.x}/#{d.y}"

a = to_direction({x: 2, y: 5}, {x: 5, y: 15})
b = to_direction({x: 7, y: 7}, {x: 10, y: 17})
print "#{a.x}/#{a.y}"
print "#{b.x}/#{b.y}"
print is_parallel(a, b)
i = intersection({a: {x: 0, y: 0}, b: {x: 1, y: 1}}, {a: {x: 1, y: 0}, b: {x: 1, y: 1}})
if i
  print "#{i.x}/#{i.y}"

wrap = (element) -> if type(element) == 'table' return element else return {element}
flatten = (list) ->
  -- print it for it in *list
  flat_list = {}
  for element in *list
    if type(element ) == 'table' and #element == 0
      continue
    for nested in *wrap(element)
      flat_list[#flat_list + 1] = nested
  return flat_list

nested = {1, 2, {3, 4}, {5, 6, 7}, 8, 9, 0}
flat = flatten(nested)

print it for it in *nested
print it for it in *flat

to_poly = (lines) ->
  -- returns a list of points {:x, :y}
  -- we only need the starting point (or endpoint) of
  -- every line segment to fully describe the polygon
  [ line.a for line in *lines ]

to_lines = (poly) ->
  lines = {}
  for i = 1, #poly - 1
    lines[#lines + 1] = { a: poly[i], b: poly[i + 1]}
  -- wrap around to close the polygon
  lines[#lines + 1] = { a: poly[#poly], b: poly[1] }
  return lines

manhattan_distance = (a, b) -> 
  math.abs(b.x-a.x) + math.abs(b.y-a.y)
to_raw_coordinates = (poly) ->
  flatten([ {poly[i].x, poly[i].y} for i=1,#poly ])

sign = (number) -> if number < 0 then -1 else 1
copysign = (x, y) ->
  -- use the magnitude of :x, and the sign of :y
  math.abs(x) * sign(y)
angle = (v) -> math.atan(v.y, v.x)
pseudo_angle = (v) -> copysign(1 - v.x/(math.abs(v.x) + math.abs(v.y)), v.y)
compare_angle = (a, b) ->
  angle = math.atan(a.y, a.x) < math.atan(b.y, b.x)
  -- print angle, "#{a.x}/#{a.y}", "#{b.x}/#{b.y}"
  angle
compare_pseudo_angle = (a, b) ->
  copysign(1 - a.x/(math.abs(a.x) + math.abs(a.y)), a.y) < copysign(1 - b.x/(math.abs(b.x) + math.abs(b.y)), b.y)
sort_by_angle = (origin, lines) ->
  table.sort(lines, (a, b) -> compare_pseudo_angle({x:a.x - origin.x, y:a.y - origin.y}, {x:b.x - origin.x, y:b.y - origin.y}))
sort_by_distance = (origin, points) ->
  table.sort(points, (a, b) -> (a.x-origin.x)^2 + (a.y-origin.y)^2 < (b.x-origin.x)^2 + (b.y-origin.y)^2)

-- print 'outline'
-- print 'nested'
-- print it for it in *to_poly(canvas)
-- print 'flat'
-- print it for it in *to_raw_coordinates(to_poly(canvas))

visibility_poly = (origin, polies) ->
  visible_area = {}
  rays = {}
  lines = flatten([ to_lines(poly) for poly in *polies ])
  for line in *lines
    -- set up all the light rays we'll be casting out
    -- each line end point is a start as well as an end -
    -- don't use them twice!
    rays[#rays + 1] = {a: origin, b: line.a}
    rays[#rays + 1] = {a: origin, b: {x: line.a.x + 0.001, y: line.a.y + 0.001}}
    rays[#rays + 1] = {a: origin, b: {x: line.a.x - 0.001, y: line.a.y - 0.001}}
  
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
 
  sort_by_angle(origin, visible_area)
   
  -- and now, let's have some post-processing:
  processed = {}
  -- for v in *visible_area
    -- make sure we have some proper, positive integers here =)
    -- v.x = math.floor(v.x)
    -- v.x = 0 if v.x < 0
    -- v.y = math.floor(v.y)
    -- v.y = 0 if v.y < 0

  -- drop all points whose relative angle or coordinates are too
  -- close the previous point's
  -- compare successive points and update point of reference
  reference = visible_area[#visible_area]
  for i=1,#visible_area
    if manhattan_distance(visible_area[i], reference) > 2 and pseudo_angle({x:visible_area[i].x - origin.x, y:visible_area[i].y - origin.y}) ~= pseudo_angle({x:reference.x - origin.x, y:reference.y - origin.y})
      processed[#processed + 1] = visible_area[i]
      reference = visible_area[i]
  return processed

-- print 'visibility poly'
-- print 'canvas:'
-- print "#{it.x}/#{it.y}" for it in *to_poly(canvas)
-- print it for it in *visibility_poly({x: 100, y: 100}, {to_poly(canvas)})

next_obstacle = nil
obstacles = {}

-- modes: normal, build
mode = 'normal'
mode_toggle = () ->
  print 'mode toggle'
  print "from #{mode}"
  if mode == 'normal'
    mode = 'build'
    next_obstacle = {}
  else if mode == 'build'
    mode = 'normal'
    if #next_obstacle > 2
      obstacles[#obstacles + 1] = copy(next_obstacle)
    next_obstacle = nil
  print "to #{mode}"

love.keypressed = (key) ->
  if key == 'delete'
    obstacles = {}

love.mousepressed = (x, y, button, _, _) ->
  print "button pressed: #{x}/#{y}, #{button}"
  if button == 1
    if mode == 'build'
      next_obstacle[#next_obstacle + 1] = {:x, :y}
  if button == 2
    -- next_obstacle[#next_obstacle + 1] = {:x, :y}
    mode_toggle()

-- print it for it in *to_list({x: 1, y: 2})
love.draw = () -> 
  screen_x, screen_y = love.graphics.getDimensions()
  canvas = {
    -- screen borders
    { a: {x: 0, y: 0}, b: {x: screen_x, y: 0} }
    { a: {x: screen_x, y: 0}, b: {x: screen_x, y: screen_y} }
    { a: {x: screen_x, y: screen_y}, b: {x: 0, y: screen_y} }
    { a: {x: 0, y: screen_y}, b: {x: 0, y: 0} }
  }
  -- print screen_x, screen_y
  -- background
  love.graphics.setColor(0.2,0.2,0.2,1)
  love.graphics.polygon('fill', to_raw_coordinates(to_poly(canvas)))
  -- obstacles
  if #obstacles > 0
    love.graphics.setColor(0,0,0,1)
    for obstacle in *obstacles
      ok, triangles = pcall(love.math.triangulate, to_raw_coordinates(obstacle))
      if not ok
        print triangles
        return
      for tri in *triangles
        -- love.graphics.setColor(0,0,0,1)
        -- love.graphics.polygon('line', tri)
        -- love.graphics.setColor(0.2,0.2,0.2,1)
        love.graphics.polygon('fill', tri)
  -- cursor
  love.mouse.setVisible(false)
  mouse_x, mouse_y = love.mouse.getPosition()
  love.graphics.setColor(0,0,0,0.5)
  love.graphics.circle('line', mouse_x, mouse_y, 4)
  love.graphics.setColor(0,0,0,0.5) if mode == 'normal'
  love.graphics.setColor(0.75,0.95,0.75,1) if mode == 'build'
  love.graphics.circle('line', mouse_x, mouse_y, 16)
  if mode == 'normal'
    love.graphics.setColor(1,1,1,1)
    -- print 'obstacles'
    -- print #obstacles
    sight_blockers = {
      to_poly(canvas)
    }
    for it in *obstacles
      sight_blockers[#sight_blockers + 1] = it
      -- for k,v in pairs(it)
      --   print "#{k}=#{v}"
    -- for it in *sight_blockers
    --   for k,v in pairs(it)
    --     print "#{k}=#{v}"
    -- print 'end of sight_blockers obstacles'
    visible_areas = {
      visibility_poly({x: mouse_x, y: mouse_y}, sight_blockers)
      visibility_poly({x: mouse_x + 4, y: mouse_y}, sight_blockers)
      visibility_poly({x: mouse_x - 4, y: mouse_y}, sight_blockers)
      visibility_poly({x: mouse_x + 4, y: mouse_y + 4}, sight_blockers)
      visibility_poly({x: mouse_x + 4, y: mouse_y - 4}, sight_blockers)
      visibility_poly({x: mouse_x - 4, y: mouse_y + 4}, sight_blockers)
      visibility_poly({x: mouse_x - 4, y: mouse_y - 4}, sight_blockers)
      visibility_poly({x: mouse_x, y: mouse_y + 4}, sight_blockers)
      visibility_poly({x: mouse_x, y: mouse_y - 4}, sight_blockers)
    }
    -- visible_area = {}
    -- visible_area = visibility_poly({x: mouse_x, y: mouse_y}, sight_blockers)
    for visible_area in *visible_areas
      if #visible_area > 2 and mouse_x > 0 and mouse_y > 0 and mouse_x < screen_x and mouse_y < screen_y
        ok, triangles = pcall(love.math.triangulate, to_raw_coordinates(visible_area))
        if not ok
          print triangles
          print 'visible area for drawing'
          print i, pseudo_angle(visible_area[i]), pseudo_angle({x: visible_area[i].x - mouse_x, y: visible_area[i].y - mouse_y}), visible_area[i].x, visible_area[i].y for i=1,#visible_area
          print 'is convex?', love.math.isConvex(to_raw_coordinates(visible_area))
          return
        love.graphics.setColor(1,1,1,0.15)
        love.graphics.polygon('fill', tri) for tri in *triangles
    if #visible_areas > 0
      love.graphics.setColor(0,1,0,1)
      love.graphics.print(i, visible_areas[1][i].x, visible_areas[1][i].y) for i=1,#visible_areas[1]
      love.graphics.setColor(0.85,0.15,0.15,1)
      love.graphics.line(mouse_x, mouse_y, point.x, point.y) for point in *visible_areas[1]
      love.graphics.circle('fill', point.x, point.y, 4) for point in *visible_areas[1]
  -- next obstacle
  if mode == 'build' and next_obstacle ~= nil
    if #next_obstacle > 1
      -- draw existing line segments
      love.graphics.setColor(0.55,0.55,0.95,1)
      love.graphics.line(to_raw_coordinates(next_obstacle))
    if #next_obstacle > 0
      -- draw potential next line segment
      love.graphics.setColor(0.25,0.95,0.25,1)
      love.graphics.line({next_obstacle[#next_obstacle].x, next_obstacle[#next_obstacle].y, mouse_x, mouse_y})
      -- draw potential final line segment
      love.graphics.setColor(0.55,0.95,0.55,1)
      love.graphics.line({
        next_obstacle[#next_obstacle].x
        next_obstacle[#next_obstacle].y
        next_obstacle[1].x
        next_obstacle[1].y
      })
  -- fps counter
  love.graphics.setColor(0,0,0,0.5)
  love.graphics.polygon('fill', to_raw_coordinates({
    {x:0, y:0}
    {x:100, y:0}
    {x:100, y:100}
    {x:0, y:100}
  }))
  love.graphics.setColor(0,1,0,0.75)
  love.graphics.print(love.timer.getFPS(), 30, 30, 0, 2.5, 2.5)

love.load = () ->
  love.window.setMode(1920, 1080, {resizable:true, vsync:true, msaa:2, minwidth:400, minheight:300})
