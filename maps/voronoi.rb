require 'ruby_vor'

Point = Struct.new(:x, :y, :annotations) do
  def initialize(x:, y:, annotations: {})
    super(x, y, annotations)
  end

  def distance_to(point)
    Math.hypot(point.x - x, point.y - y)
  end

  def ==(other)
    other.x == x && other.y == y
  end

  def hash
    x.to_i ^ y.to_i
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

  def hash
    v1.hash ^ v2.hash
  end

  def ==(other)
    v1 == other.v1 && v2 == other.v2
  end
end

Polygon = Struct.new(:edges, :center, :annotations) do
  def initialize(edges:, center:, annotations: {})
    super(edges, center, annotations)
  end

  def contains_edge?(edge)
    edges.any? { |e| e == edge }
  end

  def hash
    edges.hash ^ center.hash
  end

  def ==(other)
    edges == other.edges && center == other.center
  end
end

class Voronoi
  attr_reader :points, :vertices, :edges, :polygons, :edge_to_polygons, :vertex_to_polygons

  def initialize(number_of_points, width, height)
    random_points = number_of_points.times.map do |_i|
      x = rand(width.to_f)
      y = rand(height.to_f)
      RubyVor::Point.new(x, y)
    end
    comp = RubyVor::VDDT::Computation.from_points(random_points)
    calculate(comp)
  end

  def calculate(comp)
    @vertices = comp.voronoi_diagram_raw
                    .select { |(type, _, _)| type == :v }
                    .map { |(_, x, y)| Point.new(x: x, y: y) }

    @edges = comp.voronoi_diagram_raw
                 .select { |(type, _, _, _)| type == :e }
                 .map { |(_, _, v1, v2)| [v1, v2] }
                 .select { |(v1, v2)| v1 != -1 && v2 != -1 }
                 .map { |(v1, v2)| Edge.new(v1: vertices[v1], v2: vertices[v2]) }

    @points = comp.points.map { |i| Point.new(x: i.x, y: i.y) }

    @polygons = @points.map do |point|
      Polygon.new(edges: [], center: point)
    end

    @edge_to_polygons = Hash.new { |k, v| k[v] = Set.new }
    @vertex_to_polygons = Hash.new { |k, v| k[v] = Set.new }

    edges.each do |e|
      nearest_points = points.each_with_index.sort_by do |(point, _)|
        e.midpoint.distance_to(point)
      end
      nearest_points[0..1].each do |(_, idx)|
        @polygons[idx].edges << e
        @edge_to_polygons[e] << idx
        @vertex_to_polygons[e.v1] << idx
        @vertex_to_polygons[e.v2] << idx
      end
    end
  end
end
