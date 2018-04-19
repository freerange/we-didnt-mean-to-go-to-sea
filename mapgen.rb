require 'ruby_vor'

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

map_width = MAP.first.length
map_height = MAP.length

width = 1000
height = 1000
number_of_points = 1000

random_points = number_of_points.times.map do |_i|
  x = rand(width)
  y = rand(height)
  RubyVor::Point.new(x, y)
end

comp = RubyVor::VDDT::Computation.from_points(random_points)

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

def vertex_in_map(vertex, width, height)
  x, y = vertex
  x >= 0 && x <= width && y >= 0 && y <= height
end


vertices = comp.voronoi_diagram_raw
               .select { |(type, _, _)| type == :v }
               .map { |(_, x, y)| [x, y] }

edges = comp.voronoi_diagram_raw
            .select { |(type, _, _, _)| type == :e }
            .map { |(_, _, v1, v2)| [v1, v2] }
            .select { |(v1, v2)| v1 != -1 && v2 != -1 }
            .map { |(v1, v2)| [vertices[v1], vertices[v2]] }
            .select { |(v1, v2)| vertex_in_map(v1, width, height) && vertex_in_map(v2, width, height) }

points = comp.points.map { |i| i }

edges_with_pindexes = edges.map do |(v1, v2)|
  v1x, v1y = v1
  v2x, v2y = v2
  midpoint_x = (v1x + v2x) / 2.0
  midpoint_y = (v2y + v1y) / 2.0
  nearest_points = points.each_with_index.sort_by do |(point, _)|
    Math.hypot(point.x - midpoint_x, point.y - midpoint_y)
  end
  nearest_points = nearest_points[0..1].map { |(_, index)| index }
  [v1, v2, nearest_points]
end

polygons = Hash.new { |h, k| h[k] = [] }
edges_with_pindexes.each do |(v1, v2, nearest_points)|
  nearest_points.each do |idx|
    polygons[idx] << [v1, v2]
  end
end

require 'chunky_png'
colors = {
  land: ChunkyPNG::Color('green'),
  sea: ChunkyPNG::Color('blue'),
  coastline: ChunkyPNG::Color('grey'),
  unknown: ChunkyPNG::Color('pink'),
  coastlineline: ChunkyPNG::Color('white')
}

edge_types = edges_with_pindexes.map do |(v1, v2, ps)|
  ps = ps.map do |idx|
    center = points[idx]
    type_of_map_point(center.x, center.y, width, height, map_width, map_height)
  end.sort
  [v1, v2, ps]
end

png = ChunkyPNG::Image.new(width, height)
polygons.each_pair do |idx, ex|
  center = points[idx]
  type = type_of_map_point(center.x, center.y, width, height, map_width, map_height)
  color = colors[type]
  ex.each do |(v1, v2)|
    e1_x, e1_y = v1
    e2_x, e2_y = v2
    triangle = [[e1_x, e1_y], [e2_x, e2_y], [center.x, center.y], [e1_x, e1_y]]
    png.polygon(triangle, color, color)
  end
end

edge_types.each do |(v1, v2, types)|
  e1_x, e1_y = v1
  e2_x, e2_y = v2
  if types == %i[coastline sea]
    png.line(e1_x.to_i, e1_y.to_i, e2_x.to_i, e2_y.to_i, colors[:coastlineline])
  end
end

cell_width = width / map_width
cell_height = height / map_height
width.times do |x|
  height.times do |y|
    rx = x * cell_width
    ry = y * cell_height
    png.rect(rx, ry, rx + 2, ry + 2, colors[:coastline], colors[:coastline])
  end
end

png.save('map.png', interlace: true)
