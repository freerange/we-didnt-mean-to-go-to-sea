require 'test/unit'
require_relative 'game'

class GameTest < Test::Unit::TestCase

  def test_go_north
    start_state = State.new(5,5) 
    game = Game.new
    _, next_state = game.step(start_state, :go_north)
    assert_equal(State.new(5,6), next_state)
  end
  
  def test_go_south
    start_state = State.new(5,5) 
    game = Game.new
    _, next_state = game.step(start_state, :go_south)
    assert_equal(State.new(5,4), next_state)
  end
end
