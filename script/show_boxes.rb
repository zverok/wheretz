require 'bundler/setup'
require 'rmagick'

class GeoDraw
  def initialize(draw, max_x, max_y)
    @draw, @max_x, @max_y = draw, max_x, max_y
  end

  def rectangle(x1, y1, x2, y2)
    @draw.rectangle(x_geo2img(x1), y_geo2img(y1), x_geo2img(x2), y_geo2img(y2))
  end

  def polygon(*points)
    @draw.polygon(
      *points.each_slice(2).map{|x, y|
        [x_geo2img(x), y_geo2img(y)]
      }.flatten
    )
  end

  include Math
  
  def x_geo2img(lng)
    rescale(lng, -180..180, 0..@max_x) #.tap{|res| p "x: #{lng} => #{res}"}
  end

  def y_geo2img(lat)
    π = PI
    φ = -lat * π / 180
    
    rescale(
      log(tan(π / 4 + φ / 2)),
      -π..π, 0..@max_y
    ) #.tap{|res| p "y: #{lat} => #{res}"}
  end

  def rescale(num, from, to)
    fromdistance = from.end - from.begin
    todistance = to.end - to.begin
    (num - from.begin).to_f / fromdistance * todistance + to.begin
  end
end

class Magick::Draw
  def geo
    @geo or fail("Call Draw#setup_geo beforehands")
  end

  def setup_geo(w, h)
    @geo = GeoDraw.new(self, w, h)
  end
end

include Magick

img = Image.new(1000, 1000){|i| i.background_color = 'white'}
draw = Draw.new.stroke('red').stroke_width(1).fill('transparent')
draw.setup_geo(1000, 1000)

#Dir['data/*.geojson'].each do |f|
Dir['data/Europe*.geojson'].each do |f|
  _, *coords = f.sub('.geojson', '').split('__')
  minx, maxx, miny, maxy = coords.map(&:to_f)
  draw.geo.rectangle(minx, miny, maxx, maxy)
end

draw.draw(img)

img.write('tmp/tzones.png')
