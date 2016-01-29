require 'bundler/setup'
require 'progress_bar/core_ext/enumerable_with_progress'
require 'fileutils'
require 'rgeo'
require 'rgeo/geo_json'

TOLERANCE = 0.1

all_features = []

FileUtils.mkdir_p 'data/simplified'

Dir['data/*.geojson'].each_with_progress do |file|
  collection = RGeo::GeoJSON.decode(File.read(file), json_parser: :json)
  sgeom = collection.first.geometry.simplify_preserve_topology(TOLERANCE)
  sfeature = RGeo::GeoJSON::Feature.new(sgeom, nil, collection.first.properties)
  all_features << sfeature
  scoll = RGeo::GeoJSON::FeatureCollection.new([sfeature])
  File.write(file.sub('data/', 'data/simplified/'), RGeo::GeoJSON.encode(scoll).to_json)
end

all_coll = RGeo::GeoJSON::FeatureCollection.new(all_features)
File.write('data/simplified/world.geojson', RGeo::GeoJSON.encode(all_coll).to_json)
