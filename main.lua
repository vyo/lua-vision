require 'love'
require 'state'
require 'graphics'
require 'input'

love.update = function (dt)
  state.update(dt)
end
