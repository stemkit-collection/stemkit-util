=begin
  vim: sw=2:

  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/config/spot-locator.rb'

module SK
  module Config
    class UprootLocator < SpotLocator
      def initialize(*args)
        super(*args) { |_item, _spot, _locator|
          parent = File.dirname(_spot)
          parent =~ %r{^(.:)*[/\\]$}  ? {} : {
            :locator => self.class.new(options.merge Hash[ :item => _item, :spot => parent, :locator => _locator])
          }
        }
      end

      class << self
        def [](item, locator = nil)
          new :item => item, :spot => '.', :locator => locator
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
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
