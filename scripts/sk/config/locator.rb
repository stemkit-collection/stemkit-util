=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

module SK
  module Config
    class Locator
      def initialize(*args)
        @options = args.inject({}) { |_hash, _item|
          _hash.update Hash[_item]
        }
      end

      def invoke(processor)
        locator.invoke(processor) if locator?
      end

      protected
      #########

      def options
        @options
      end

      def spot
        options[:spot] || '.'
      end

      def locator?
        options.has_key :locator
      end

      def locator
        option[:locator] || raise 'No locator'
      end

    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    module Config
      class LocatorTest < Test::Unit::TestCase
        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
