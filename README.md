# fluent-plugin-graphite [![Build Status](https://travis-ci.org/studio3104/fluent-plugin-graphite.png)](https://travis-ci.org/studio3104/fluent-plugin-graphite) [![Code Climate](https://codeclimate.com/github/studio3104/fluent-plugin-graphite.png)](https://codeclimate.com/github/studio3104/fluent-plugin-graphite)

fluentd output plugin to send metrics to graphite

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-graphite'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-graphite

## Configuration

#### Example

message: `metrics { "f1":"100", "f2":"200", "f3":"300" }`

###### Specify name_keys

- configuration

  ```
  <match metrics>
    type graphite
    host localhost
    port 2003
    protocol udp
    tag_for prefix
    name_keys f1,f3
  </match>
  ```

- output graph_name

  ```
  metrics.f1
  metrics.f3
  ```

###### Specify name_key_pattern

- configuration

  ```
  <match metrics>
    type graphite
    host localhost
    port 2003
    protocol udp
    tag_for prefix
    name_key_pattern f\d
  </match>
  ```

- output graph_name

  ```
  metrics.f1
  metrics.f2
  metrics.f3
  ```

###### tag_for suffix

- configuration

  ```
  <match metrics>
    type graphite
    host localhost
    port 2003
    protocol udp
    tag_for suffix
    name_keys f1,f2
  </match>
  ```

- output graph_name

  ```
  f1.metrics
  f2.metrics
  ```

###### tag_for ignore

- configuration

  ```
  <match metrics>
    type graphite
    host localhost
    port 2003
    protocol udp
    tag_for ignore
    name_keys f1,f2
  </match>
  ```

- output graph_name

  ```
  f1
  f2
  ```

#### Parameter

###### host
- required.
- ip address or hostname of graphite server.

###### port
- Default is `2003`.
- listening port of carbon-cache.

###### protocol
- Default is `udp`
- socket protocol such as `tcp`, `udp`.

###### tag_for
- Default is `prefix`.
- Either of `prefix`, `suffix` or `ignore`.
  - `prefix` uses the tag name as graph_name prefix.
  - `suffix` uses the tag name as graph_name suffix.
  - `ignore` uses the tag name for nothing.

###### name_keys
- Either of `name_keys` or `name_key_pattern` is required.
- Specify field names of the input record. Separate by , (comma). The values of these fields are posted as numbers, and names of thease fields are used as parts of grame_names.

###### name_key_pattern
- Either of `name_keys` or `name_key_pattern` is required.
- Specify the field names of the input record by a regular expression. The values of these fields are posted as numbers, and names of thease fields are used as parts of grame_names.

###### remove_tag_prefix, remove_tag_suffix, add_tag_prefix, add_tag_suffix
- Setting for rewriting the tag.
- For more information: https://github.com/y-ken/fluent-mixin-rewrite-tag-name

## Contributing

1. Fork it ( http://github.com/studio3104/fluent-plugin-graphite/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
