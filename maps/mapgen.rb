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

Point = Struct.new(:x, :y, :annotations) do
  def initialize(x:, y:, annotations: {})
    super(x, y, annotations)
  end

  def distance_to(point) 
    Math.hypot(point.x - x, point.y - y)
  end
end

Edge = Struct.new(:v1, :v2, :annotations) do
  def initialize(v1:, v2:, annotations: {})
    super(v1, v2, annotations)
  end

  def midpoint
    midpoint_x = (v1.x + v2.x) / 2.0
    midpoint_y = (v2.y + v1.y) / 2.0
    Point.new(x: midpoint_x, y: midpoint_y)
  end
end

Polygon = Struct.new(:edges, :center, :annotations) do
  def initialize(edges:, center:, annotations: {})
    super(edges, center, annotations)
  end
end

random_points = number_of_points.times.map do |_i|
  x = rand(width)
  y = rand(height)
  RubyVor::Point.new(x, y)
end

comp = RubyVor::VDDT::Computation.from_points(random_points)

vertices = comp.voronoi_diagram_raw
               .select { |(type, _, _)| type == :v }
               .map { |(_, x, y)| Point.new(x: x, y: y) }

edges = comp.voronoi_diagram_raw
            .select { |(type, _, _, _)| type == :e }
            .map { |(_, _, v1, v2)| [v1, v2] }
            .select { |(v1, v2)| v1 != -1 && v2 != -1 }
            .map { |(v1, v2)| Edge.new(v1: vertices[v1], v2: vertices[v2]) }

points = comp.points.map { |i| Point.new(x: i.x, y: i.y) }

edges_with_pindexes = edges.map do |e|
  nearest_points = points.each_with_index.sort_by do |(point, _)|
    e.midpoint.distance_to(point) 
  end
  nearest_points = nearest_points[0..1]
  [e, nearest_points]
end

polygons = Hash.new
edges_with_pindexes.each do |(e, nearest_points)|
  nearest_points.each do |(point, idx)|
    if !polygons[idx]
      polygons[idx] = Polygon.new(edges: [], center: point)
    end
    polygons[idx].edges << e
  end
end
polygons = polygons.values

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


require 'chunky_png'
colors = {
  land: ChunkyPNG::Color('green'),
  sea: ChunkyPNG::Color('blue'),
  coastline: ChunkyPNG::Color('grey'),
  unknown: ChunkyPNG::Color('pink'),
  coastlineline: ChunkyPNG::Color('white')
}

png = ChunkyPNG::Image.new(width, height, colors[:sea])
polygons.each do |p|
  color = colors[p.annotations[:tile_type]]
  p.edges.each do |e|
    triangle = [[e.v1.x, e.v1.y], [e.v2.x, e.v2.y], [p.center.x, p.center.y], [e.v1.x, e.v1.y]]
    png.polygon(triangle, color, color)
  end
end

edges.each do |e|
  types = e.annotations[:tile_types]
  if types == %i[coastline sea]
    png.line(e.v1.x.to_i, e.v1.y.to_i, e.v2.x.to_i, e.v2.y.to_i, colors[:coastlineline])
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
