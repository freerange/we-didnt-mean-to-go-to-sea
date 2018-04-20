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

def annotate_polygons_with_neighbourhood(polygons)
  polygons.each do |p|
    p.annotations[:neighbourhood] = [p.annotations[:tile_type]] 
    p.edges.each do |e|
      neighbours = e.polygons.reject {|poly| poly == p }.map { |poly| poly.annotations[:tile_type] }
      p.annotations[:neighbourhood] = p.annotations[:neighbourhood] + neighbours
    end
    p.annotations[:neighbourhood] = p.annotations[:neighbourhood].uniq.sort
  end
end

def each_triangle_with_tile_type(polygons)
  polygons.each do |p|
    type = p.annotations[:tile_type]
    p.edges.each do |e|
      triangle = [[e.v1.x, e.v1.y], [e.v2.x, e.v2.y], [p.center.x, p.center.y]]
      yield type, triangle
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

def stretch_coastline(polygons)
  polygons.each do |poly|
    if poly.annotations[:neighbourhood] == [:coastline] || poly.annotations[:neighbourhood] == %i[coastline land]
      poly.annotations[:tile_type] = :land
    end
  end
end

map_width = MAP.first.length
map_height = MAP.length


cell_width = width / map_width.to_f

grid_marker_size = width / 250

voronoi = Voronoi.new(number_of_points, width, height)

annotate_polygons_with_tile_types(voronoi.polygons, width, height, map_width, map_height)
annotate_polygons_with_neighbourhood(voronoi.polygons)
stretch_coastline(voronoi.polygons)

colors = {
  land: 'green',
  sea: 'light blue',
  coastline: 'grey',
  unknown: 'pink',
  coastlineline: 'white'
}

require_relative './chunky_graphics'
graphics = ChunkyGraphics.new(width, height, colors[:sea])

each_triangle_with_tile_type(voronoi.polygons) do |type, triangle|
  color = colors[type]
  graphics.polygon(triangle, color, color)
end

each_coastline_edge(voronoi.edges) do |(x1,y1),(x2,y2)|
  graphics.line(x1.to_i, y1.to_i, x2.to_i, y2.to_i, colors[:coastlineline])
end

each_grid_center(MAP, width, height, map_width, map_height) do |rx,ry|
  graphics.rect(rx, ry, rx + grid_marker_size, ry + grid_marker_size, colors[:coastline])
end

graphics.save("map#{number_of_points_per_grid_square}-#{width}x#{height}")