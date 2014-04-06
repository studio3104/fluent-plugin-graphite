class Fluent::GraphiteOutput < Fluent::Output
  Fluent::Plugin.register_output('graphite', self)
end
