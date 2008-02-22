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
        super *arg.push(:spot => '~')
      end

      class << self
        def [](item, locator = nil)
          new :item => item, :locator => locator
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
      class UprootLocatorTest < Test::Unit::TestCase
        def setup
        end
      end
    end
  end
end
