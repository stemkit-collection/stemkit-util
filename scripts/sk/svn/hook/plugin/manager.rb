=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

module SK
  module Svn
    module Hook
      module Plugin
        class Manager
          attr_reader :client

          def initialize(client, *extra, &block)
            @client = client
            @extra = extra
          end

          def invoke(info)
            plugin_instances.each do |_plugin|
              client.report_error('Plugin processing') {
                _plugin.process(info)
              }
            end
          end

          protected
          #########

          def plugins
            client.config.plugins(client.repository).map { |_plugin|
              load_plugin(_plugin)
            } + @extra
          end

          def plugin_instances
            @plugin_instances ||= plugins.compact.uniq.map { |_klass|
              instantiate_plugin(_klass)
            }.compact
          end

          def instantiate_plugin(plugin)
            client.report_error('Plugin instantiation') {
              return plugin.new(client.config)
            }
            nil
          end

          def load_plugin(spec)
            client.report_error("Plugin #{spec.inspect} load") {
              components = spec.split('::')
              require File.join(module_paths(components[0...-1]), class_file(components.last))

              return components.inject(Module) { |_module, _constant|
                _module.const_get(_constant)
              }
            }
            nil
          end

          def module_paths(names)
            names.map { |_name| 
              _name.downcase 
            }
          end

          def class_file(name)
            name.scan(%r{[A-Z][a-z0-9_]*}).map { |_c| _c.downcase }.join('-')
          end
        end
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    module Svn
      module Hook
        class PluginManagerTest < Test::Unit::TestCase
          def setup
          end
          
          def teardown
          end
        end
      end
    end
  end
end
