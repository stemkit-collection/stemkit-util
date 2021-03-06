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
        @options.delete_if { |_key, _value|
          _value.nil?
        }
      end

      def invoke(processor)
        locator.invoke(processor) if locator?
      end

      def locator?
        options.has_key? :locator
      end

      def locator
        options[:locator] or raise 'No locator'
      end

      protected
      #########

      def options
        @options
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Config
      class LocatorTest < Test::Unit::TestCase
        attr_reader :processor, :mock_locator

        def test_standalone
          locator = Locator.new
          processor.expects(:process).never

          locator.invoke(processor)
        end

        def test_cascading
          locator = Locator.new :locator => Locator.new(:locator => mock_locator)
          processor.expects(:process).never
          mock_locator.expects(:invoke).with(processor)

          locator.invoke(processor)
        end

        def setup
          @processor = mock('processor')
          @mock_locator = mock('locator')
        end
      end
    end
  end
end
