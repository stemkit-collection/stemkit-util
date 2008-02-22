=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'tsc/errors.rb'
require 'sk/config/locator.rb'

module SK
  module Config
    class SpotLocator < Locator
      def initialize(*args)
        super

        if block_given?
          options.update Hash[ yield options[:item], spot, options[:locator] ]
        end
      end

      def invoke(processor)
        super

        TSC::Error.ignore Errno::ENOENT do
          File.open File.join(spot, item) do |_io|
            processor.process(_io, spot)
          end
        end
      end

      def spot
        @spot ||= File.expand_path(options[:spot] || '.')
      end

      def item
        options[:item] || locator.item
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
      class SpotLocatorTest < Test::Unit::TestCase
        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
