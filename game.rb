MAP = ["LLLLLLLC~~",
      "LLLLLLLC~~",
      "LLLCLLLC~~",
      "LLC~CHC~~~",
      "LLC~B~~~B~",
      "LLP~~~~~~~",
      "LC~~~~~~~~",
      "LC~~~~~~CC",
      "CC~B~~CCLC",
      "~~~~~B~CC~"]


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
  def initialize(tiles)
    @tiles = tiles
    @features = parse_features
  end

  def each_tile
    height = @tiles.length
    @tiles.map.with_index do |tile_row, y|
      tile_row.chars.map.with_index do |tile_col, x|
        yield [tile_col, x, (height - 1) - y]
      end
    end
  end

  def parse_features
    features = []
    each_tile do |tile, x, y|
      feature_map = {
        "B" => ["Buoy", 0.5],
        "C" => ["Coastline", 0.5],
        "H" => ["Lighthouse", 1.0]
      }
      if fv  = feature_map[tile]
        feature, volume = fv
        features << Feature.new(feature, x, y, volume)
      end
    end
    features
  end

  def draw_boat_at(bx, by)
    each_tile do |tile, x, y|
     if x == 0 
       puts
     end
     if bx == x && by == y
       print "^"
     else
       print tile
     end
    end
    puts
  end

  def features_audible_from(x, y)
    @features.map {|f| [f, f.volume_from(x, y)] }
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

  def draw_on_map(map)
    map.draw_boat_at(@x, @y)
  end
end

class TextResponder
  ACK = "Aye aye, Captain"

  def success(state)
    [ACK, state]
  end

  def listen(features_and_volume, state)
    above_hearing_threshold = features_and_volume.select {|(_, fv)| fv >0.05 }
    response = "You can hear: "+
      above_hearing_threshold.map do |(f,fv)|
        f.name + " (" + adverb(fv) + ")" 
      end.join(",")
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
    when :noop
      @responder.success(state)
    end
  end

end

if __FILE__ == $0

  map = Map.new(MAP)
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
    when "cheat"
      state.draw_on_map(map)
      game.step(state, :noop)
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

