class Feature
  attr_reader :name
  def initialize(name, x, y, volume)
    @name = name
    @x = x
    @y = y
    @volume = volume
  end
  
  def distance_from(x, y)
    xdiff = (x - @x).abs
    ydiff = (y - @y).abs
    Math.sqrt(xdiff * xdiff + ydiff * ydiff)
  end

  def volume_from(x, y)
    @volume * distance_from(x, y) 
  end
end

class Map
  def initialize(features)
    @features = features
  end

  def features_audible_from(x, y)
    @features.map {|f| [f, f.volume_from(x, y)] }.select {|(_,fv)| fv < 3 } 
  end
end

class State
  def initialize(x, y)
    @x = x
    @y = y
  end

  def move(dx, dy)
    State.new(@x + dx, @y + dy)
  end

  def same_position?(x, y)
    x == @x && y == @y
  end

  def ==(another_state)
    another_state.same_position?(@x, @y) 
  end

  def audible_features(map)
    map.features_audible_from(@x, @y)
  end
end

class Game
  def initialize(map)
    @map = map
  end
  
  ACK = "Aye aye, Captain"
  def step(state, action)
    case action
    when :go_north
      [ACK, state.move(0, 1) ] 
    when :go_south
      [ACK, state.move(0, -1) ] 
    when :go_west
      [ACK, state.move(-1, 0) ] 
    when :go_east
      [ACK, state.move(1, 0) ] 
    when :listen
      [sounds_for_state(@map, state), state]
    end
  end

  def sounds_for_state(map, state)
    audible_features = state.audible_features(map)
    "You can hear: "+audible_features.map {|(f,fv)| f.name + " (" + adverb(fv) + ")" }.join(",")
  end

  def adverb(volume)
    case volume
    when 0...1
      "very loudly"
    when 1...2
      "loudly"
    when 2...3
      "in the distance"
    else
      "barely"
    end
  end
end

if __FILE__ == $0

  features = [
    Feature.new('Buoy', 7, 7, 1),
    Feature.new('Buoy', 7, 4, 1),
    Feature.new('Buoy', 3, 2, 1),
    Feature.new('Buoy', 4, 6, 1),
    Feature.new('Lighthouse', 4, 8, 2)
  ]
  map = Map.new(features)
  game = Game.new(map)

  state = State.new(Random.rand(5)+3, Random.rand(5)+3)
  while true do
    print "> "
    command = gets.chomp
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
    if state.same_position?(2,5)
      print "You're home"
      exit 0
    end
    puts ack
  end
end

