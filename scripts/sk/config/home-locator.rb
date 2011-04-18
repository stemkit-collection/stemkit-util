=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/config/spot-locator.rb'

module SK
  module Config
    class HomeLocator < SpotLocator
      def initialize(*args)
        super *args.push(:spot => '~')
      end

      class << self
        def [](item, locator = nil)
          new :item => item, :locator => locator
        end
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'
  
  module SK
    module Config
      class UprootLocatorTest < Test::Unit::TestCase
        def test_standalone
          locator = HomeLocator[ 'aaa' ]
          HomeLocator.expects(:expand_path).with('~').returns('/home/user')

          assert_equal 'aaa', locator.item
          assert_equal '/home/user', locator.spot
        end

        def setup
        end
      end
    end
  end
end
