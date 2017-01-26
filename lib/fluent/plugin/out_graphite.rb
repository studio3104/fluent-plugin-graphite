require 'fluent/mixin/rewrite_tag_name'

class Fluent::GraphiteOutput < Fluent::Output
  Fluent::Plugin.register_output('graphite', self)

  include Fluent::HandleTagNameMixin
  include Fluent::Mixin::RewriteTagName

  config_param :host, :string
  config_param :port, :integer, default: 2003
  config_param :tag_for, :string, default: 'prefix'
  config_param :name_keys, :string, default: nil
  config_param :name_key_pattern, :string, default: nil

  # Define `log` method for v0.10.42 or earlier
  unless method_defined?(:log)
    define_method(:log) { $log }
  end

  def initialize
    super
    require 'graphite-api'
  end

  def start
    super
    connect_client!
  end

  def configure(conf)
    super

    if !['prefix', 'suffix', 'ignore'].include?(@tag_for)
      raise Fluent::ConfigError, 'out_graphite: can specify to tag_for only prefix, suffix or ignore'
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
    # How many times to retry the call if timeout raised
    @max_retries ||= 3
  end

  def emit(tag, es, chain)
    es.each do |time, record|
      emit_tag = tag.dup
      filter_record(emit_tag, time, record)
      next unless metrics = format_metrics(emit_tag, record)

      # implemented to immediate call post method in this loop, because graphite-api.gem has the buffers.
      post(metrics, time)
    end

    chain.next
  end

  def format_metrics(tag, record)
    filtered_record = if @name_keys
                        record.select { |k,v| @name_keys.include?(k.to_s) }
                      else # defined @name_key_pattern
                        record.select { |k,v| @name_key_pattern.match(k.to_s) }
                      end

    return nil if filtered_record.empty?

    metrics = {}
    tag = tag.sub(/\.$/, '') # may include a dot at the end of the emit_tag fluent-mixin-rewrite-tag-name returns. remove it.
    filtered_record.each do |k, v|
      key = case @tag_for
            when 'ignore' then k.to_s
            when 'prefix' then "#{tag}.#{k}"
            when 'suffix' then "#{k}.#{tag}"
            end

      key = key.gsub(/(\s|\/)+/, '_') # cope with in the case of containing symbols or spaces in the key of the record like in_dstat.
      metrics[key] = v.to_f
    end
    metrics
  end

  def post(metrics, time)
    trial ||= 1
    @client.metrics(metrics, time)
  rescue Errno::ETIMEDOUT
    # after long periods with nothing emitted, the connection will be closed and result in timeout
    if trial <= @max_retries
      log.warn "out_graphite: connection timeout to #{@host}:#{@port}. Reconnecting... "
      trial += 1
      connect_client!
      retry
    else
      log.error "out_graphite: ERROR: connection timeout to #{@host}:#{@port}. Exceeded max_retries #{@max_retries}"
    end
  rescue Errno::ECONNREFUSED
    log.warn "out_graphite: connection refused by #{@host}:#{@port}"
  rescue SocketError => se
    log.warn "out_graphite: socket error by #{@host}:#{@port} :#{se}"
  rescue StandardError => e
    log.error "out_graphite: ERROR: #{e}"
  end
  
  def connect_client!
    @client = GraphiteAPI.new(graphite: "#{@host}:#{@port}")
  end
end
