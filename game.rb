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
    distance = distance_from(x, y) + 1 
    @volume / (distance * distance)
  end
end

class Map
  def initialize(features)
    @features = features
  end

  def features_audible_from(x, y, threshold = 0)
    @features.map {|f| [f, f.volume_from(x, y)] }.select {|(_,fv)| fv > threshold }.shuffle 
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

class TextResponder
  ACK = "Aye aye, Captain"

  def success(state)
    [ACK, state]
  end

  def listen(features_and_volume, state)
    response = "You can hear: "+features_and_volume.map {|(f,fv)| f.name + " (" + adverb(fv) + ")" }.join(",")
    [response, state]
  end
    
  def adverb(volume)
    case volume
    when 1
      "ear-splittingly loud"
    when 0.5..1 
      "very loudly"
    when 0.25...0.5 
      "loudly"
    when 0.11...0.25
      "in the distance"
    else
      "barely"
    end
  end
end

class Game
  def initialize(map, responder)
    @map = map
    @responder = responder
  end
  
  def step(state, action)
    case action
    when :go_north
      @responder.success(state.move(0, 1)) 
    when :go_south
      @responder.success(state.move(0, -1)) 
    when :go_west
      @responder.success(state.move(-1, 0)) 
    when :go_east
      @responder.success(state.move(1, 0)) 
    when :listen
      @responder.listen(state.audible_features(@map), state)
    end
  end

end

if __FILE__ == $0

  map = Map.new(features)
  game = Game.new(map, TextResponder.new)

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

