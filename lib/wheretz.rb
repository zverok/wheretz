# frozen_string_literal: true

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
      zone = zone.gsub('--', '/')
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

  def lookup_geo(lat, lng, candidate_files)
    point = [lng, lat]

    polygons = candidate_files.map { |fname, zone, *| [zone, geom_from_file(fname)] }
    candidates = polygons.select { |_, multipolygon| inside_multipolygon?(multipolygon, point) }

    case candidates.size
    # Since switching to tz-boundary-builder, there should be no "empty" spaces anymore
    when 0 then fail ArgumentError, 'Point outside any known timezone'
    when 1 then candidates.first.first
    else candidates.map(&:first)
    end
  end

  def geom_from_file(fname)
    JSON.parse(File.read(fname)).dig('features', 0 , 'geometry')
  end

  def inside_multipolygon?(multipolygon, point)
    polygons(multipolygon).any? { |polygon| contains_point?(polygon, point) }
  end

  # Previously each timezones geojson always contained multypolygon, now it can be just
  # a simple polygon. Make it polymorphic.
  #
  # If it is polygon, ['coordinates'] contains its geometry (array of linear rings, each is array of points)
  # If it is multypolygon, ['coordinates'] is an _array_ of such geometries
  def polygons(geometry)
    case geometry['type']
    when 'Polygon'
      [geometry['coordinates']]
    when 'MultiPolygon'
      geometry['coordinates']
    else
      raise ArgumentError, "Unsupported geometry type: #{geometry['type']}"
    end
  end

  def contains_point?(polygon, (x, y))
    # Taken from GeoRuby's Polygon#contains_point?, which just delegates to LinearRing#contains_point?
    # Polygon's geometry is just an array of linear ring; linear ring is array of points.
    polygon.any? { |points|
      [*points, points.first]
        .each_cons(2)
        .select { |(xa, ya), (xb, yb)|
          (yb > y != ya > y) && (x < (xa - xb) * (y - yb) / (ya - yb) + xb)
        }.size % 2 == 1
    }
  end

  # Last resort: pretty slow check for the cases when the point
  # is slightly outside polygons.
  # See https://github.com/zverok/wheretz/issues/4
  # NB: Not used currently, since switching to timezone-boundary-builder _with oceans_, there are
  # no empty spaces anymore.
  # Left here in case we'll switch to timezones-without-oceans dataset at some point.
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
