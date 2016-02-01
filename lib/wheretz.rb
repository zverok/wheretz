require 'geo_ruby'
require 'geo_ruby/geojson'

# WhereTZ is quick and simple time zone lookup by geographic point.
#
# Usage:
#
# ```ruby
# WhereTZ.lookup(50.004444, 36.231389)
# # => 'Europe/Kiev'
# 
# WhereTZ.get(50.004444, 36.231389)
# # => #<TZInfo::DataTimezone: Europe/Kiev>
# ```
module WhereTZ
  # @private
  FILES =
    Dir[File.expand_path('../../data/*.geojson', __FILE__)].
    map{|f|
      name = File.basename(f).sub('.geojson', '')
      zone, *coords = name.split('__')
      zone = zone.tr('-', '/')
      minx, maxx, miny, maxy = coords.map(&:to_f)
      [f, zone, minx..maxx, miny..maxy]
    }.freeze

  # Exception (possibly) raised when point is inside several
  # time zone polygons simultaneously.
  AmbigousTimezone = Class.new(RuntimeError)

  module_function

  # Time zone name by coordinates.
  #
  # @param lat Latitude (floating point number)
  # @param lng Longitude (floating point number)
  #
  # @return [String] time zone name or `nil` if no time zone corresponds
  #   to (lat, lng)
  def lookup(lat, lng)
    candidates =
      FILES.
      select{|_f, _z, xr, yr| xr.cover?(lng) && yr.cover?(lat)}

    case candidates.size
    when 0 then nil
    when 1 then candidates.first[1]
    else
      lookup_geo(lat, lng, candidates)
    end
  end

  # `TZInfo::DataTimezone` object by coordinates.
  #
  # Note that you should add `tzinfo` to your Gemfile to use this method.
  # `wheretz` doesn't depend on `tzinfo` by itself.
  #
  # @param lat Latitude (floating point number)
  # @param lng Longitude (floating point number)
  #
  # @return [TZInfo::DataTimezone] timezone object or `nil` if no
  #   timezone corresponds to (lat, lng)
  def get(lat, lng)
    begin
      require 'tzinfo'
    rescue LoadError
      raise LoadError, 'Please install tzinfo for using #get'
    end

    name = lookup(lat, lng)
    name && TZInfo::Timezone.get(name)
  end

  private

  PARSER = GeoRuby::GeoJSONParser.new

  module_function

  class GeoRuby::SimpleFeatures::MultiPolygon
    def contains_point?(point)
      geometries.any?{|polygon| polygon.contains_point?(point)}
    end
  end

  def lookup_geo(lat, lng, candidates)
    point = GeoRuby::SimpleFeatures::Point.from_coordinates([lng, lat])

    candidates = candidates.map{|fname, zone, *|
      [zone, PARSER.parse(File.read(fname)).features.first.geometry]
    }.select{|_, polygon|
      polygon.contains_point?(point)
    }

    case candidates.size
    when 0 then nil
    when 1 then candidates.first.first
    else
      fail(AmbigousTimezone, "Ambigous timezone: #{candidates.map(&:first)}")
    end
  end
end
