export state = {}

export obstacles = {}

export point_of_view = {x:0,y:0}
alpha = math.pi
state.view_angle = alpha
state.view_angle_vector = {x:math.cos(state.view_angle),y:math.sin(state.view_angle)}
state.wide_segment = {
  a: {x: state.view_angle_vector.x + 60, y: state.view_angle_vector.y + 1}
  b: {x: state.view_angle_vector.x - 60, y: state.view_angle_vector.y + 1}
}
state.narrow_segment = {
  a: {x: state.view_angle_vector.x + 5, y: state.view_angle_vector.y + 10}
  b: {x: state.view_angle_vector.x - 5, y: state.view_angle_vector.y + 10}
}

state.update = () ->
  state.view_angle_vector = {x:math.cos(state.view_angle),y:math.sin(state.view_angle)}
  wide_a = {x:math.cos(state.view_angle - math.pi/2),y:math.sin(state.view_angle - math.pi/2)}
  wide_b = {x:math.cos(state.view_angle + math.pi/2),y:math.sin(state.view_angle + math.pi/2)}
  narrow_a = {x:math.cos(state.view_angle - math.pi/4),y:math.sin(state.view_angle - math.pi/4)}
  narrow_b = {x:math.cos(state.view_angle + math.pi/4),y:math.sin(state.view_angle + math.pi/4)}
  -- print view_angle
  -- print "#{view_angle_vector.x}/#{view_angle_vector.y}"
  state.wide_segment = {
    a: wide_a
    b: wide_b
  }
  state.narrow_segment = {
    a: narrow_a
    b: narrow_b
  }

