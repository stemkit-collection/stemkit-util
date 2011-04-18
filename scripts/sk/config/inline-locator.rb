=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/config/locator.rb'

module SK
  module Config
    class InlineLocator < Locator
      def invoke(processor)
        super

        processor.process(content, nil)
      end

      def content
        options[:content] or raise 'No content'
      end

      class << self
        def [](content, locator = nil)
          new :content => content, :locator => locator
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
    module Config
      class InlineLocatorTest < Test::Unit::TestCase
        attr_reader :processor

        def test_stanalone
          locator = InlineLocator.new :content => "abcdefg"
          processor.expects(:process).with('abcdefg', nil)

          locator.invoke(processor)
        end

        def test_cascading
          locator = InlineLocator.new :content => 'aaa', :locator => InlineLocator['bbb', InlineLocator['ccc'] ]
          processor.expects(:process).with('ccc', nil)
          processor.expects(:process).with('bbb', nil)
          processor.expects(:process).with('aaa', nil)

          locator.invoke(processor)
        end

        def setup
          @processor = mock('processor')
        end
      end
    end
  end
end
