require 'chunky_png'
require 'chunky_png/rmagick'
require 'RMagick'

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

  def with_image_magick
    image  = ChunkyPNG::RMagick.export(@png)
    image = yield image
    @png  = ChunkyPNG::RMagick.import(image)
  end

  def blur(radius)
    with_image_magick do |image|
      image = image.blur_image(0,radius)
      image = image.add_noise(Magick::GaussianNoise)
    end
  end

  def border(width, color)
    with_image_magick do |image|
      image.border(width, width, color)
    end
  end

  def blend(color1, color2, factor)
    factor = (255 * factor).to_i
    ChunkyPNG::Color.interpolate_quick(ChunkyPNG::Color(color1), ChunkyPNG::Color(color2), factor)
  end

  def polygon(points, stroke, fill)
    @png.polygon(points, color_for(stroke), color_for(fill))
  end

  def line(width, x1, y1, x2, y2, color)
    with_image_magick do |image|
      imgl = Magick::ImageList.new
      imgl << image
      draw = Magick::Draw.new
      path = "M #{x1} #{y1} T #{x2} #{y2}"
      draw.stroke(color)
      draw.stroke_width(width)
      draw.path(path)
      draw.draw(imgl)
      imgl.flatten_images
    end
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
