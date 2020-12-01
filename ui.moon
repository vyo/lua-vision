require 'love.graphics'

export ui = {}
ui.fps = () ->
  -- fps counter
  love.graphics.setColor(0,0,0,1)
  love.graphics.polygon('fill', to_raw_coordinates({
    {x:0, y:0}
    {x:100, y:0}
    {x:100, y:100}
    {x:0, y:100}
  }))
  love.graphics.setColor(0,1,0,1)
  love.graphics.print(love.timer.getFPS(), 30, 30, 0, 2.5, 2.5)

ui.mode = (mode) ->
  screen_x, screen_y = love.graphics.getDimensions()
  -- ui mode indicator
  love.graphics.setColor(0,0,0,1)
  love.graphics.polygon('fill', to_raw_coordinates({
    {x:0, y:101}
    {x:100, y:101}
    {x:100, y:200}
    {x:0, y:200}
  }))
  love.graphics.setColor(0,1,0,1)
  love.graphics.print(mode, 15, 130, 0, 1.5, 1.5)

ui.fov = (fov) ->
  screen_x, screen_y = love.graphics.getDimensions()
  -- ui mode indicator
  love.graphics.setColor(0,0,0,1)
  love.graphics.polygon('fill', to_raw_coordinates({
    {x:0, y:201}
    {x:100, y:201}
    {x:100, y:300}
    {x:0, y:300}
  }))
  love.graphics.setColor(0,1,0,1)
  love.graphics.print(fov.angle, 30, 230, 0, 1.5, 1.5)

