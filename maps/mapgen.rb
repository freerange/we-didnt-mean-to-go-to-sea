require_relative './voronoi'

MAP = ['LLLLLLLC~~',
       'LLLLLLLC~~',
       'LLLCLLLC~~',
       'LLC~CHC~~~',
       'LLC~B~~~B~',
       'LLP~~~~~~~',
       'LC~~~~~~~~',
       'LC~~~~~~CC',
       'CC~B~~CCLC',
       '~~~~~B~CC~']

def is_land_tile?(tile)
  ["L","H","P"].include? tile
end

def build_height_map(map)
  top_bottom = ['X' * (map.first.length + 2)]
  bordered_map = top_bottom +
    map.map {|row| ('X' + row + 'X').chars } +
    top_bottom
  heights = Array.new(map.length){Array.new(map.first.length,0.1)}
  map.length.times do |y|
    map.first.length.times do |x|
      border_x = x + 1
      border_y = y + 1
      next unless is_land_tile?(bordered_map[border_y][border_x]) 
      neighbours = [
        bordered_map[border_x+1][border_y+1],
        bordered_map[border_x+0][border_y+1],
        bordered_map[border_x-1][border_y+1],
        bordered_map[border_x+1][border_y+0],
        bordered_map[border_x+0][border_y+0],
        bordered_map[border_x-1][border_y+0],
        bordered_map[border_x+1][border_y-1],
        bordered_map[border_x+0][border_y-1],
        bordered_map[border_x-1][border_y-1],
      ].reject {|t| t == "X" }  
      height = neighbours.select {|t| is_land_tile?(t) }.length  / neighbours.length.to_f
      heights[y][x] = height  
    end
  end
  heights
end

def type_of_map_point(x, y, width, height, map_width, map_height)
  map_x = x / (width / map_width)
  map_y = y / (height / map_height)
  map_tile =  MAP[map_y][map_x]
  case map_tile
  when 'L'
    :land
  when '~', 'B'
    :sea
  when 'C', 'H', 'P'
    :coastline
  else
    :unknown
  end
end

def annotate_polygons_with_tile_types(polygons, width, height, map_width, map_height)
  polygons.each do |p|
    type = type_of_map_point(p.center.x, p.center.y, width, height, map_width, map_height)
    p.annotations[:tile_type] = type
    p.edges.each do |e|
      if !e.annotations[:tile_types]
        e.annotations[:tile_types] = []
      end
      e.annotations[:tile_types] = (e.annotations[:tile_types] + [type]).uniq.sort
    end
  end
end

def annotate_polygons_with_neighbourhood(polygons, edge_to_polygons)
  polygons.each do |p|
    p.annotations[:neighbourhood] = [p.annotations[:tile_type]] 
    p.edges.each do |e|
      edge_polygons = edge_to_polygons[e]
      neighbours = edge_polygons.reject {|poly| poly == p }.map { |poly| poly.annotations[:tile_type] }
      p.annotations[:neighbourhood] = p.annotations[:neighbourhood] + neighbours
    end
    p.annotations[:neighbourhood] = p.annotations[:neighbourhood].uniq.sort
  end
end

def each_triangle_with_tile_type(polygons)
  polygons.each do |p|
    type = p.annotations[:tile_type]
    pheight = p.annotations[:height]
    p.edges.each do |e|
      triangle = [[e.v1.x, e.v1.y], [e.v2.x, e.v2.y], [p.center.x, p.center.y]]
      yield type, triangle, pheight 
    end
  end
end

def each_coastline_edge(edges)
  edges.each do |e|
    types = e.annotations[:tile_types]
    if types == %i[coastline sea] || types == %i[land sea]
      yield [e.v1.x, e.v1.y], [e.v2.x, e.v2.y]
    end
  end
end

def each_grid_center(map, width, height, map_width, map_height)
  cell_width = width / map_width.to_f
  cell_height = height / map_height.to_f
  map_width.times do |x|
    map_height.times do |y|
      rx = x * cell_width + cell_width / 2.0
      ry = y * cell_height + cell_height / 2.0
      yield rx.to_i, ry.to_i if ["~","B"].include? map[y][x]
    end
  end
end

def each_icon_to_draw(map, cell_width, icon_size)
  map.each_with_index do |row, y|
    row.chars.each.with_index do |col, x|
      x_pos = cell_width * x + icon_size / 2
      y_pos = cell_width * y + icon_size / 2
      image = case col
        when 'B'
          :buoy
        when 'H'
          :lighthouse
        when 'P'
          :port
      end
      yield image, x_pos, y_pos if image
    end
  end
end

def stretch_coastline(polygons)
  polygons.each do |poly|
    if poly.annotations[:neighbourhood] == [:coastline] || poly.annotations[:neighbourhood] == %i[coastline land]
      poly.annotations[:tile_type] = :land
    end
  end
end

def annotate_polygons_with_height(polygons, map, width, height, map_width, map_height)
  height_map = build_height_map(map) 
  polygons.each do |poly|
    grid_x = poly.center.x / (width / map_width)
    grid_y = poly.center.y / (height / map_height)
    if grid_x < map_width && grid_y < map_height
      tile_height = height_map[grid_y.to_i][grid_x.to_i]
      poly.annotations[:height] = tile_height * 0.9 * (rand(0.2)+0.9)
    else
      poly.annotations[:height] = 0
    end
  end
end

map_width = MAP.first.length
map_height = MAP.length

if ARGV.length != 3
  $stderr.puts "ruby mapgen.rb voronoi_points_per_square width height"
  exit 1
end

number_of_points_per_grid_square, width, height = ARGV.map {|i| i.to_i }
number_of_points_per_grid_square = ARGV[0].to_i
number_of_points =  number_of_points_per_grid_square * map_width * map_height 

cell_width = width / map_width.to_f

icon_size = (cell_width / 2).to_i
grid_marker_size = width / 250

voronoi = Voronoi.new(number_of_points, width, height)

annotate_polygons_with_tile_types(voronoi.polygons, width, height, map_width, map_height)
annotate_polygons_with_neighbourhood(voronoi.polygons, voronoi.edge_to_polygons)
annotate_polygons_with_height(voronoi.polygons, MAP, width, height, map_width, map_height)
stretch_coastline(voronoi.polygons)

colors = {
  land_high: 'green',
  land: 'goldenrod',
  sea: 'light blue',
  coastline: 'grey',
  unknown: 'pink',
  coastlineline: 'light grey'
}

require_relative './chunky_graphics'
graphics = ChunkyGraphics.new(width, height, colors[:sea])

each_triangle_with_tile_type(voronoi.polygons) do |type, triangle, pheight|
  next unless [:land, :coastline].include? type
  color = case type
          when :land
            graphics.blend(colors[:land_high], colors[:land], pheight**2)
          else
            colors[:coastline]
          end
  graphics.polygon(triangle, color, color)
end

graphics.blur

each_triangle_with_tile_type(voronoi.polygons) do |type, triangle, pheight|
  next if [:land, :coastline].include? type
  color = colors[type]
  graphics.polygon(triangle, color, color)
end

each_coastline_edge(voronoi.edges) do |(x1,y1),(x2,y2)|
  graphics.line(x1.to_i, y1.to_i, x2.to_i, y2.to_i, colors[:coastlineline])
end

each_grid_center(MAP, width, height, map_width, map_height) do |rx,ry|
  graphics.rect(rx, ry, rx + grid_marker_size, ry + grid_marker_size, colors[:coastline])
end

each_icon_to_draw(MAP, cell_width, icon_size) do |image, x_pos, y_pos|
  graphics.icon(image, x_pos, y_pos, icon_size) if image
end

graphics.save("map#{number_of_points_per_grid_square}-#{width}x#{height}")
