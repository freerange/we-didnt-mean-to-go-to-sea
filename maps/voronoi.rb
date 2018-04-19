require 'ruby_vor'

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

class Voronoi
  attr_reader :points, :vertices, :edges, :polygons

  def initialize(number_of_points, width, height)
    random_points = number_of_points.times.map do |_i|
      x = rand(width)
      y = rand(height)
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
    @polygons = polygons.values
  end
end
