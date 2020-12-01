require 'state'

export next_obstacle = nil

-- modes: view, build
export mode = 'view'
export mode_toggle = () ->
  print 'mode toggle'
  print "from #{mode}"
  if mode == 'view'
    mode = 'build'
    next_obstacle = {}
  else if mode == 'build'
    mode = 'view'
    if #next_obstacle > 2
      obstacles[#obstacles + 1] = copy(next_obstacle)
    next_obstacle = nil
  print "to #{mode}"

love.keypressed = (key) ->
  if key == 'delete'
    obstacles = {}
    next_obstacle = {}
  else if key == 'q'
    -- print 'rotating counter-clockwise'
    -- print state.view_angle
    -- print "#{state.view_angle_vector.x}/#{state.view_angle_vector.y}"
    state.view_angle = (state.view_angle - 0.125*math.pi) % (math.pi*2)
    -- print state.view_angle
    -- print "#{state.view_angle_vector.x}/#{state.view_angle_vector.y}"
  else if key == 'e'
    -- print 'rotating clockwise'
    -- print state.view_angle
    -- print "#{state.view_angle_vector.x}/#{state.view_angle_vector.y}"
    state.view_angle = (state.view_angle + 0.125*math.pi) % (math.pi*2)
    -- print state.view_angle
    -- print "#{state.view_angle_vector.x}/#{state.view_angle_vector.y}"

love.mousepressed = (x, y, button, _, _) ->
  print "button pressed: #{x}/#{y}, #{button}"
  if button == 1
    if mode == 'build'
      next_obstacle[#next_obstacle + 1] = {:x, :y}
  else if button == 2
    mode_toggle()

