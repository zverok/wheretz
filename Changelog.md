# WhereTZ changelog

## 0.0.6 (2020-05-02)

* Update timezones info to 2020d (latest available in [
timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder/releases), though there is [2021a](https://www.iana.org/time-zones) already...);
* Slight code style updates.

## 0.0.5 (2020-04-25)

* Update timezones info to 2020a;
* Change timezone files naming to fix problems with zones named like `Asia/Ust-Nera` ([@jotolo](https://github.com/jotolo), [#9](https://github.com/zverok/wheretz/pull/9));
* Remove GeoRuby dependency: after profiling it turned out to be major slowdown, just copy-pasted sole relevant algorithm to work with bare JSON.

## 0.0.4 (2020-04-25)

(unreleased due to some rubygems problem)

* Update timezones info to 2019b (latest available from timezone-boundary-builder)

## 0.0.3 (2019-06-28)

* Data source updated to timezone-boundary-builder (tz_world_map, used previously, is deprecated)
* In (not so rare, as it turned out) case of ambigous timezone, instead of exception, just a list of timezones is returned

## 0.0.2 (2016-03-04)

Fixed edge case (point slightly outside any of polygon).

## 0.0.1 (2016-01-28)

Initial.
