require 'geo_ruby'
require 'geo_ruby/geojson'

module WhereTZ
  FILES = Dir[File.expand_path('../../data/*.geojson', __FILE__)].map{|f|
    zone, *coords = f.sub(/^.+data\//, '').sub('.geojson', '').split('__')
    zone = zone.gsub('-', '/')
    minx, maxx, miny, maxy = coords.map(&:to_f)
    [f, zone, minx..maxx, miny..maxy]
  }.freeze

  AmbigousTimezone = Class.new(RuntimeError)

  module_function

  def lookup(lat, lng)
    candidates = FILES.select{|fname, zone, x, y| x.cover?(lng) && y.cover?(lat)}
    case candidates.size
    when 0
      nil
    when 1
      candidates.first[1]
    else
      lookup_geo(lat, lng, candidates)
    end
  end

  def get(lat, lng)
    begin
      require 'tzinfo'
    rescue LoadError
      raise LoadError, "Please install tzinfo for using #get"
    end

    name = lookup(lat, lng)
    name && TZInfo::Timezone.get(name)
  end

  private
  module_function
  PARSER = GeoRuby::GeoJSONParser.new
  
  def lookup_geo(lat, lng, candidates)
    point = GeoRuby::SimpleFeatures::Point.from_coordinates([lng, lat])

    candidates = candidates.map{|fname, zone, *|
      [zone, PARSER.parse(File.read(fname)).features.first.geometry]
    }.select{|zone, multipolygon|
      multipolygon.geometries.any?{|polygon| polygon.contains_point?(point)}
    }

    case candidates.size
    when 0
      nil
    when 1
      candidates.first.first
    else
      fail(AmbigousTimezone, "Ambigous timezone: #{candidates.map(&:first)}")
    end
  end
end
