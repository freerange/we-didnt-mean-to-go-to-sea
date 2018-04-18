require 'sinatra'
require_relative 'game'

get '/' do
  map = Map.new(MAP)
  game = Game.new(map, TextResponder.new)

  state = State.new(Random.rand(5)+3, Random.rand(5)+3)
  ack, state = game.step(state, :listen)
  {
    ack: ack,
    state: state
  }.to_json
end

post '/' do
  json = request.body.read
  data = JSON.parse(json)

  map = Map.new(MAP)
  game = Game.new(map, TextResponder.new)

  x = data['state']['x']
  y = data['state']['y']
  command = data['command']

  state = State.new(x, y)

  ack, state = case command
  when "north"
    game.step(state, :go_north)
  when "south"
    game.step(state, :go_south)
  when "east"
    game.step(state, :go_east)
  when "west"
    game.step(state, :go_west)
  when "listen"
    game.step(state, :listen)
  else
    ["Huh?", state ]
  end

  if game.status(state) == :in_port
    ack = "You're home!!"
  elsif game.status(state) == :aground
    ack = "You crashed!!"
  end

  {
    ack: ack,
    state: state
  }.to_json
end
