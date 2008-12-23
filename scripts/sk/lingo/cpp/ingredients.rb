=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

module SK
  module Lingo
    module Cpp
      module Ingredients 
        def header_includes
          lines data['header_includes']
        end

        def header_bottom
          lines data['header_bottom']
        end

        def body_top
          lines data['body_top']
        end

        def body_includes
          lines data['body_includes']
        end

        def extends
          lines data['extends']
        end

        def initializes
          lines data['initializes']
        end

        def private_data_members
          lines data['data']
        end
        
        def constructors
          klass = Struct.new(:parameters, :body, :comments)
          process_methods(data['factory']) { |_returns, _name, _parameters, _body, _comments|
            klass.new(_parameters, _body, _comments) if _name == 'constructor'
          }.compact
        end

        def destructors
          klass = Struct.new(:type, :body, :comments)
          process_methods(data['factory']) { |_returns, _name, _parameters, _body, _comments|
            klass.new(_returns, _body, _comments) if _name == 'destructor'
          }.compact
        end

        def class_init
          lines data['class_init']
        end

        def public_methods
          @public_methods ||= map_methods(data['public_methods'])
        end

        def protected_methods
          @protected_methods ||= map_methods(data['protected_methods'])
        end

        def private_methods
          @private_methods ||= map_methods(data['private_methods'])
        end
        
        private
        #######
        
        def process_methods(methods, &block)
          return [] unless block and Hash === methods

          methods.map { |_declaration, _body|
            returns, name, parameters = _declaration.scan(%r{^(.*?)\s*(\w+)\s*([(][^)]*[)].*)$}).first
            comments, body = lines(_body).partition { |_line|
              _line.match %r{^\s*//}
            }
            block.call returns, name, parameters, body, comments
          }
        end

        def map_methods(methods)
          klass = Struct.new(:returns, :signature, :body, :comments)
          process_methods(methods) { |_returns, _name, _parameters, _body, _comments|
            klass.new _returns, "#{_name}#{_parameters}", _body, _comments
          }
        end
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    module Lingo
      class ConfigTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
