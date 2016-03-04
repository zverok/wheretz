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

  def lookup_geo(lat, lng, candidates)
    point = GeoRuby::SimpleFeatures::Point.from_coordinates([lng, lat])

    polygons = candidates.map{|fname, zone, *|
      [zone, PARSER.parse(File.read(fname)).features.first.geometry]
    }
    candidates = polygons.select{|_, multipolygon|
      multipolygon.geometries.any?{|polygon| polygon.contains_point?(point)}
    }

    case candidates.size
    when 0 then guess_outside(point, polygons)
    when 1 then candidates.first.first
    else
      fail(AmbigousTimezone, "Ambigous timezone: #{candidates.map(&:first)}")
    end
  end

  # Last resort: pretty slow check for the cases when the point
  # is slightly outside polygons.
  # See https://github.com/zverok/wheretz/issues/4
  def guess_outside(point, polygons)
    # create pairs [timezone, distance to closest point of its polygon]
    distances = polygons.map{|zone, multipolygon|
      [
        zone,
        multipolygon.geometries.map(&:rings).flatten.
          map{|p| p.ellipsoidal_distance(point)}.min
      ]
    }

    # FIXME: maybe need some tolerance range for maximal reasonable distance?

    distances.sort_by(&:last).first.first
  end
end
