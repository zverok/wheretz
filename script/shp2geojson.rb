require 'bundler/setup'
require 'progress_bar/core_ext/enumerable_with_progress'
require 'geo_ruby'
require 'geo_ruby/shp'

shapefile = GeoRuby::Shp4r::ShpFile.open('script/data/world/tz_world_mp.shp')

shapefile.with_progress.map{|shp|
  bmin, bmax = shp.geometry.bounding_box
  name = shp.data.attributes['TZID']
  next if name == 'uninhabited'
  
  fname = "script/data/%s__%.4f__%.4f__%.4f__%.4f.geojson" % [name.gsub('/', '-'), bmin.x, bmax.x, bmin.y, bmax.y]
  File.write(fname,
    {
      "type" => "FeatureCollection",
      "features" => [
        {
          "type" => "Feature",
          "properties" => {'timezone' => shp.data.attributes['TZID']},
          "geometry" => shp.geometry.as_json
        }
      ]
    }.to_json
  )
}
