require 'helper'

class GraphiteOutputTest < Test::Unit::TestCase
  CONFIG = %[
    host graphite
    port 2003
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::GraphiteOutput, tag).configure(conf)
  end
end
