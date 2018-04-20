require 'chunky_png'
class ChunkyGraphics

  IMAGES = {
   buoy: ChunkyPNG::Image.from_file('buoy.png'),
   lighthouse: ChunkyPNG::Image.from_file('lighthouse.png'),
   port:  ChunkyPNG::Image.from_file('port.png')
  }

  def initialize(width, height, background)
    @png = ChunkyPNG::Image.new(width, height, color_for(background))
  end

  def color_for(name)
    ChunkyPNG::Color(name)
  end

  def polygon(points, stroke, fill)
    @png.polygon(points, color_for(stroke), color_for(fill))
  end

  def line(x1, y1, x2, y2, color)
    @png.line(x1.to_i, y1.to_i, x2.to_i, y2.to_i, color_for(color))
  end

  def rect(x1, y1, x2, y2, color)
    @png.rect(x1, y1, x2, y2, color_for(color), color_for(color))
  end
  
  def icon(image, x1, y1, size)
    if image = IMAGES[image]
      @png.replace!(image.resize(size, size), x1, y1)
    end
  end

  def save(filename)
    @png.save("#{filename}.png", interlace: true)
  end
end