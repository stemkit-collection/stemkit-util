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
      class Locator
        def initialize(options, cwd)
          @options, @cwd = options, cwd

          @top, @kind, rest = @cwd.scan(%r{^(.+)/(lib|include)/(.*)*$}).first
          @components = rest ? rest.split('/') : []
        end

        def namespace(namespace)
          namespace.empty? ? @components : namespace
        end

        def path_for(kind, file)
          return file if (local? or @kind == kind)

          directory = [ '..' ] * @components.size.next + [ kind, *@components ]
          File.join directory, file
        end

        def header_specification(name, extension)
          file = [ name, extension ].join('.')
          return '"' + file + '"' if local?

          '<' + File.join(@components, file) + '>'
        end

        private
        #######
        
        def local?
          @is_local ||= (@options.has_key?('local') or @top.nil?)
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
      module Cpp
        class LocatorTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
