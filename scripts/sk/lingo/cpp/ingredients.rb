# vim: set sw=2:
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
          lines target['header_includes']
        end

        def header_bottom
          lines target['header_bottom']
        end

        def body_top
          lines target['body_top']
        end

        def body_includes
          lines target['body_includes']
        end

        def extends
          lines target['extends']
        end

        def initializes
          lines target['initializes']
        end

        def private_data_members
          lines target['data']
        end
        
        def constructors
          process_methods(target['factory']) { |_returns, _name, _parameters, _body, _comments|
            TSC::Dataset[ :parameters => _parameters, :body => _body, :comments => _comments ] if _name == 'constructor'
          }.compact
        end

        def destructors
          process_methods(target['factory']) { |_kind, _name, _parameters, _body, _comments|
            TSC::Dataset[ :kind => _kind, :body => _body, :comments => _comments ] if _name == 'destructor'
          }.compact
        end

        def class_init
          lines target['class_init']
        end

        def public_methods
          @public_methods ||= map_methods(target['public_methods'])
        end

        def protected_methods
          @protected_methods ||= map_methods(target['protected_methods'])
        end

        def private_methods
          @private_methods ||= map_methods(target['private_methods'])
        end
        
        private
        #######
        
        def process_methods(methods, &block)
          return [] unless block and methods

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
