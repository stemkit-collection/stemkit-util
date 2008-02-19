=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

module SK
  module Lingo
    class Locator
      def initialize(options, cwd)
        @options, @cwd = options, cwd

        @top, @kind, rest = @cwd.scan(%r{^(.+)/(lib|include)/(.*)*$}).first
        @components = rest ? rest.split('/') : []
      end

      def namespace(namespace)
        namespace.empty? ? @components : namespace
      end

      def figure_for(kind, name, extension)
        file = name + '.' + extension
        return file if (local? or @kind == kind)

        directory = [ '..' ] * @components.size.next + [ kind, *@components ]
        File.join directory, file
      end

      def header_specification(name, extension)
        file = name + '.h'
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

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    module Lingo
      class LocatorTest < Test::Unit::TestCase
        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
