require 'bundler/setup'
require 'geo_ruby'
require 'geo_ruby/geojson'
require 'open-uri'
require 'zip'
require 'byebug'


# download and unzip latest data
data_source_file_name = 'timezones-with-oceans.geojson.zip'
unzipped_file_name = 'combined-with-oceans.json'

unless File.exist?(data_source_file_name)
  open(data_source_file_name, 'wb') do |file|
    file << open("https://github.com/evansiroky/timezone-boundary-builder/releases/latest/download/#{data_source_file_name}").read
  end
  # unzip into
  Zip::File.open(data_source_file_name) do |zip_file|
    zip_file.each do |f|
      zip_file.extract(f, unzipped_file_name) unless File.exist?(unzipped_file_name)
    end
  end
end

def write_geojson(name, polygon)
  bmin, bmax = polygon.bounding_box
  fname = "tzdata/%s__%.4f__%.4f__%.4f__%.4f.geojson" % [name.gsub('/', '--'), bmin.x, bmax.x, bmin.y, bmax.y]
  File.write(fname,
    {
      "type" => "FeatureCollection",
      "features" => [
        {
          "type" => "Feature",
          "properties" => {'timezone' => name},
          "geometry" => polygon.as_json
        }
      ]
    }.to_json
  )
end

parser = GeoRuby::GeoJSONParser.new
parser.parse(File.read(unzipped_file_name))

parser.geometry.features.each do |feature|
  name = feature.properties['tzid']

  if feature.respond_to?(:geometry) && feature.geometry.class == GeoRuby::SimpleFeatures::MultiPolygon
    for polygon in feature.geometry.geometries do
      write_geojson(name, polygon)
    end
  else
    write_geojson(name, feature.geometry)
  end
end
