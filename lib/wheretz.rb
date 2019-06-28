# frozen_string_literal: true

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
  extend self

  # @private
  FILES =
    Dir[File.expand_path('../data/*.geojson', __dir__)].
    map { |f|
      name = File.basename(f).sub('.geojson', '')
      zone, *coords = name.split('__')
      zone = zone.tr('-', '/')
      minx, maxx, miny, maxy = coords.map(&:to_f)
      [f, zone, minx..maxx, miny..maxy]
    }.freeze

  # Time zone name by coordinates.
  #
  # @param lat Latitude (floating point number)
  # @param lng Longitude (floating point number)
  #
  # @return [String, nil, Array<String>] time zone name, or `nil` if no time zone corresponds
  #   to (lat, lng); in rare (yet existing) cases of ambiguous timezones may return an array of names
  def lookup(lat, lng)
    candidates = FILES.select { |_f, _z, xr, yr| xr.cover?(lng) && yr.cover?(lat) }

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
  # @return [TZInfo::DataTimezone, nil, Array<TZInfo::DataTimezone>] timezone object or `nil` if no
  #   timezone corresponds to (lat, lng); in rare (yet existing) cases of ambiguous timezones may
  #   return an array of timezones
  def get(lat, lng)
    begin
      require 'tzinfo'
    rescue LoadError
      raise LoadError, 'Please install tzinfo for using #get'
    end

    name = lookup(lat, lng)
    case name
    when String
      TZInfo::Timezone.get(name)
    when Array
      name.map(&TZInfo::Timezone.method(:get))
    end
  end

  private

  PARSER = GeoRuby::GeoJSONParser.new

  def lookup_geo(lat, lng, candidate_files)
    point = GeoRuby::SimpleFeatures::Point.from_coordinates([lng, lat])

    polygons = candidate_files.map { |fname, zone, *| [zone, geom_from_file(fname)] }
    candidates = polygons.select { |_, multipolygon| inside_multipolygon?(multipolygon, point) }

    case candidates.size
    when 0 then guess_outside(point, polygons)
    when 1 then candidates.first.first
    else
      candidates.map(&:first)
    end
  end

  def geom_from_file(fname)
    PARSER.parse(File.read(fname)).features.first.geometry
  end

  def inside_multipolygon?(multipolygon, point)
    polygons(multipolygon).any? { |polygon| polygon.contains_point?(point) }
  end

  # Previously each timezones geojson always contained multypolygon, now it can be just
  # a simple polygon. Make it polymorphic
  def polygons(geometry)
    case geometry
    when GeoRuby::SimpleFeatures::Polygon
      [geometry]
    when GeoRuby::SimpleFeatures::MultiPolygon
      geometry.geometries
    else
      raise ArgumentError, "Unsupported geometry type: #{geometry.class}"
    end
  end

  # Last resort: pretty slow check for the cases when the point
  # is slightly outside polygons.
  # See https://github.com/zverok/wheretz/issues/4
  def guess_outside(point, geometries)
    # create pairs [timezone, distance to closest point of its polygon]
    distances = geometries.map { |zone, multipolygon|
      [
        zone,
        polygons(multipolygon).map(&:rings).flatten.
          map { |p| p.ellipsoidal_distance(point) }.min
      ]
    }

    # FIXME: maybe need some tolerance range for maximal reasonable distance?

    distances.min_by(&:last).first
  end
end
