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
          options.update Hash[ yield(options[:item], spot, options[:locator]) ]
        end
      end

      def invoke(processor)
        super

        TSC::Error.ignore Errno::ENOENT do
          self.class.open File.join(spot, item) do |_io|
            processor.process(_io, spot)
          end
        end
      end

      def spot
        @spot ||= self.class.expand_path(options[:spot] || '.')
      end

      def item
        options[:item] || locator.item
      end

      class << self
        def expand_path(*args)
          File.expand_path(*args)
        end

        def open(*args, &block)
          File.open(*args, &block)
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
    module Config
      class SpotLocatorTest < Test::Unit::TestCase
        attr_reader :processor

        def test_standalone_no_item_default_spot
          locator = SpotLocator.new
          File.expects(:expand_path).with('.').returns('/a/b/c')
          processor.expects(:process).never

          assert_raises RuntimeError do
            locator.item
          end
          assert_equal '/a/b/c', locator.spot
        end

        def test_cascading_with_tailing_item
          locator = SpotLocator.new :locator => SpotLocator.new(:item => 'zzz')
          processor.expects(:process).never

          assert_equal 'zzz', locator.item
        end

        def test_cascading_invoke
          locator = SpotLocator.new :locator => SpotLocator.new(:item => 'zzz', :spot => '/tmp')
          SpotLocator.expects(:expand_path).with('.').returns('/a/b')
          SpotLocator.expects(:expand_path).with('/tmp').returns('/tmp')
          SpotLocator.expects(:open).with('/a/b/zzz').yields('aaa')
          SpotLocator.expects(:open).with('/tmp/zzz').yields('bbb')

          processor.expects(:process).with('aaa', '/a/b')
          processor.expects(:process).with('bbb', '/tmp')

          locator.invoke(processor)
        end

        def setup
          @processor = mock('processor')
        end
      end
    end
  end
end
