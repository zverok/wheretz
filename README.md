WhereTZ: fast and precise timezone lookup
=========================================

**WhereTZ** is a small gem for lookup of timezone by georgraphic
coordinates.

Features:

* quite precise: uses [timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder), which takes source data from OpenStreetMap;
* (relatively) fast: 0.1-0.2 sec for lookup in worst cases and almost immediate
  lookup for best cases;
* no calls to external services, works without Internet connection;
* no keeping some 50 Mb datafiles in memory or reading them from disk
  for each call;
* can return timezone name string or `TZInfo::Timezone`.

## Usage

Install it with your usual routines (Gemfile or `gem install`) as
`wheretz` gem. Then:

```ruby
require 'wheretz'

WhereTZ.lookup(50.004444, 36.231389) # (lat, lng) order
# => 'Europe/Kiev'

WhereTZ.get(50.004444, 36.231389)
# => #<TZInfo::DataTimezone: Europe/Kiev>

# you should have tzinfo gem installed, wheretz doesn't list it as dependency
```

From command-line, after gem installed:

```bash
wheretz 50.004444,36.231389
# => Europe/Kiev
```

## How it works

1. Latest version of [timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder) dataset is converted into ~400 `data/*.geojson` files;
2. Each of those files corresponds to one timezone; filename contains
  timezone name and _bounding box_ (min and max latitude and longitude);
3. On each lookup `WhereTZ` first checks provided coordinates by bounding
  boxes, and if only one bbox (extracted from filename) corresponds to
  them, returns timezone name immediately;
4. If there's several intersecting bounding boxes, `WhereTZ` reads only
  relevant timezone files (which are not very large) and checks which
  polygon actually contains the point.
5. **Added in 0.0.2** If point occures outside any of polygons, find
  the closest one (it's last resort for really rare cases and slower
  than other approaches).

## Known problems

* On "bounding box only" check, some points deeply in sea (and actually
  belonging to no timezone polygon) can be wrongly guessed as belonging
  to some timezone;
* Loading/unloading `.geojson` files can be uneffective when called
  multiple times; future releases will provide option for preserve
  data in memory, or for mass lookup of points;
* You should note that gem has ≈50 MiB of datafiles inside;
* Data conversion performed by pretty ugly script (instead of Rake task
  as it should be).

## Author

[Victor Shepelev](http://zverok.github.io/)

## License

Data license is [ODbL](https://opendatacommons.org/licenses/odbl/).

Code license is usual MIT.
