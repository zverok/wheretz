require 'bundler/setup'
require 'progress_bar/core_ext/enumerable_with_progress'
require 'geo_ruby'
require 'geo_ruby/geojson'

# shapefile = GeoRuby::Shp4r::ShpFile.open('script/data/world/tz_world_mp.shp')
# shapefile = GeoRuby::Shp4r::ShpFile.open('script/data/world/combined-shapefile-with-oceans.shp')
parser = GeoRuby::GeoJSONParser.new

# TODO: take automatically from https://github.com/evansiroky/timezone-boundary-builder/releases
parser.parse(File.read('script/data/world/combined-with-oceans.json'))

parser.geometry.features.with_progress.each { |feature|
  bmin, bmax = feature.geometry.bounding_box
  name = feature.properties['tzid']
  next if name.start_with?('Etc/') # uninhabited zones, just clutter the data (hopefully)

  fname = "data/%s__%.4f__%.4f__%.4f__%.4f.geojson" % [name.gsub('/', '-'), bmin.x, bmax.x, bmin.y, bmax.y]
  File.write(fname,
    {
      "type" => "FeatureCollection",
      "features" => [
        {
          "type" => "Feature",
          "properties" => {'timezone' => name},
          "geometry" => feature.geometry.as_json
        }
      ]
    }.to_json
  )
}

# shapefile.with_progress.map{|shp|
#   bmin, bmax = shp.geometry.bounding_box
#   name = shp.data.attributes['TZID']
#   next if name == 'uninhabited'

#   fname = "data/%s__%.4f__%.4f__%.4f__%.4f.geojson" % [name.gsub('/', '-'), bmin.x, bmax.x, bmin.y, bmax.y]
#   File.write(fname,
#     {
#       "type" => "FeatureCollection",
#       "features" => [
#         {
#           "type" => "Feature",
#           "properties" => {'timezone' => shp.data.attributes['TZID']},
#           "geometry" => shp.geometry.as_json
#         }
#       ]
#     }.to_json
#   )
# }
