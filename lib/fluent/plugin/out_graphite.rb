require 'fluent/mixin/rewrite_tag_name'

class Fluent::GraphiteOutput < Fluent::Output
  Fluent::Plugin.register_output('graphite', self)

  include Fluent::HandleTagNameMixin
  include Fluent::Mixin::RewriteTagName
  config_param :hostname_command, :string, default: 'hostname'

  config_param :host, :string
  config_param :port, :integer, default: 2003
  config_param :tag_for_key_prefix, :bool, default: false
  config_param :tag_for_key_suffix, :bool, default: false
  config_param :name_keys, :string, default: nil
  config_param :name_key_pattern, :string, default: nil

  def initialize
    super
    require 'socket'
  end

  def configure(conf)
    super

    if !@tag && !@remove_tag_prefix && !@remove_tag_suffix && !@add_tag_prefix && !@add_tag_suffix
      raise Fluent::ConfigError, 'out_graphite: missing remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix'
    end

    if @tag_for_key_prefix && @tag_for_key_suffix
      raise Fluent::ConfigError, 'out_graphite: missing both of tag_for_key_prefix and tag_for_key_suffix'
    end
    if @tag_for_key_prefix && @tag_for_key_suffix
      raise Fluent::ConfigError, 'out_graphite: cannot specify both of tag_for_key_prefix and tag_for_key_suffix'
    end

    if !@name_keys && !@name_key_pattern
      raise Fluent::ConfigError, 'out_graphite: missing both of name_keys and name_key_pattern'
    end
    if @name_keys && @name_key_pattern
      raise Fluent::ConfigError, 'out_graphite: cannot specify both of name_keys and name_key_pattern'
    end

    if @name_keys
      @name_keys = @name_keys.split(',')
    end
    if @name_key_pattern
      @name_key_pattern = Regexp.new(@name_key_pattern)
    end
  end

  def emit(tag, es, chain)
    es.each do |time, record|
      emit_tag = tag.dup
      filter_record(emit_tag, time, record)
      next unless message = create_message(emit_tag, time, record)
      post(message)
    end

    chain.next
  end

  def create_message(tag, time, record)
    filtered_record = if @name_keys
                        record.select { |k,v| @name_keys.include?(k) }
                      else # defined @name_key_pattern
                        record.select { |k,v| @name_key_pattern.match(k) }
                      end

    return nil if filtered_record.empty?

    message = ''
    tag = tag.sub(/\.$/, '')

    filtered_record.each do |k, v|
      key = if @tag_for_key_prefix
              tag + '.' + k
            else # defined @tag_for_key_suffix
              k + '.' + tag
            end
      key = key.gsub(/\s+/, '_')
      value = v.to_f
      message = message + "#{key} #{value} #{time}\n"
    end
    message
  end

  def post(message)
    TCPSocket.open(@host, @port) { |s| s.write(message) }
  end
end
