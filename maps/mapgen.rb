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

map_width = MAP.first.length
map_height = MAP.length

width = 500
height = 500
number_of_points = 1000

voronoi = Voronoi.new(number_of_points, width, height)

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

voronoi.polygons.each do |p|
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
voronoi.polygons.each do |p|
  color = colors[p.annotations[:tile_type]]
  p.edges.each do |e|
    triangle = [[e.v1.x, e.v1.y], [e.v2.x, e.v2.y], [p.center.x, p.center.y], [e.v1.x, e.v1.y]]
    png.polygon(triangle, color, color)
  end
end

voronoi.edges.each do |e|
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
