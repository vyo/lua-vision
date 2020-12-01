require 'fov'
require 'ui'
require 'state'

love.draw = () -> 
  screen_x, screen_y = love.graphics.getDimensions()
  canvas = {
    -- screen borders
    { a: {x: 0, y: 0}, b: {x: screen_x, y: 0} }
    { a: {x: screen_x, y: 0}, b: {x: screen_x, y: screen_y} }
    { a: {x: screen_x, y: screen_y}, b: {x: 0, y: screen_y} }
    { a: {x: 0, y: screen_y}, b: {x: 0, y: 0} }
  }
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
        love.graphics.polygon('fill', tri)
  -- cursor
  love.mouse.setVisible(false)
  mouse_x, mouse_y = love.mouse.getPosition()
  love.graphics.setColor(0,0,0,0.5)
  love.graphics.circle('line', mouse_x, mouse_y, 4)
  love.graphics.setColor(0,0,0,0.5) if mode == 'view'
  love.graphics.setColor(0.75,0.95,0.75,1) if mode == 'build'
  love.graphics.circle('line', mouse_x, mouse_y, 16)
  -- print "#{state.view_angle.x}/#{state.view_angle.y}"
  if mode == 'view'
    love.graphics.setColor(1,1,1,1)
    sight_blockers = {
      to_poly(canvas)
    }
    for it in *obstacles
      sight_blockers[#sight_blockers + 1] = it
    visible_areas = {
      -- todo: re-enable
      -- visibility_poly({x: mouse_x, y: mouse_y}, sight_blockers, copy(state.wide_segment))
      visibility_poly({x: mouse_x, y: mouse_y}, sight_blockers, copy(state.narrow_segment))
      -- visibility_poly({x: mouse_x + 4, y: mouse_y}, sight_blockers)
      -- visibility_poly({x: mouse_x - 4, y: mouse_y}, sight_blockers)
      -- visibility_poly({x: mouse_x + 4, y: mouse_y + 4}, sight_blockers)
      -- visibility_poly({x: mouse_x + 4, y: mouse_y - 4}, sight_blockers)
      -- visibility_poly({x: mouse_x - 4, y: mouse_y + 4}, sight_blockers)
      -- visibility_poly({x: mouse_x - 4, y: mouse_y - 4}, sight_blockers)
      -- visibility_poly({x: mouse_x, y: mouse_y + 4}, sight_blockers)
      -- visibility_poly({x: mouse_x, y: mouse_y - 4}, sight_blockers)
    }
    for visible_area in *visible_areas
      if #visible_area > 2 and mouse_x > 0 and mouse_y > 0 and mouse_x < screen_x and mouse_y < screen_y
        ok, triangles = pcall(love.math.triangulate, to_raw_coordinates(visible_area))
        if not ok
          print triangles
          print 'visible area for drawing'
          print i, pseudo_angle(visible_area[i]), pseudo_angle({x: visible_area[i].x - mouse_x, y: visible_area[i].y - mouse_y}), visible_area[i].x, visible_area[i].y for i=1,#visible_area
          print 'is convex?', love.math.isConvex(to_raw_coordinates(visible_area))
          return
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.polygon('fill', tri) for tri in *triangles
    if #visible_areas > 0
      love.graphics.setColor(0,1,0,1)
      love.graphics.print(i, visible_areas[1][i].x, visible_areas[1][i].y) for i=1,#visible_areas[1]
      love.graphics.setColor(0.85,0.15,0.15,1)
      love.graphics.line(mouse_x, mouse_y, point.x, point.y) for point in *visible_areas[1]
      love.graphics.circle('fill', point.x, point.y, 4) for point in *visible_areas[1]
  -- draw view angle
  love.graphics.line(mouse_x, mouse_y, mouse_x + state.view_angle_vector.x*100, mouse_y + state.view_angle_vector.y*100)
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
  ui.fps()
  ui.mode(mode)
  ui.fov({angle: state.view_angle})

love.load = () ->
  love.window.setMode(640, 480, {resizable:true, vsync:true, msaa:2, minwidth:400, minheight:300})

