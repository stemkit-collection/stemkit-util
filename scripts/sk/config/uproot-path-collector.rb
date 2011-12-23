=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/config/uproot-locator.rb'

module SK
  module Config
    class UprootPathCollector < SK::Config::UprootLocator
      class Collector
        def process(paths, spot)
          depot << [ paths, spot ] unless paths.empty?
        end

        def depot
          @depot ||= []
        end
      end

      def items_with_location
        Collector.new.tap { |_collector|
          self.invoke _collector
          break _collector.depot
        }
      end

      def items
        normalize items_with_location.map { |_item, _location|
          _item
        }
      end

      def locations
        items_with_location.map { |_item, _location|
          _location
        }
      end

      private
      #######

      def normalize(*args)
        args.flatten.compact
      end
      
      def content(path)
        Dir[path]
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Config
      class UprootPathCollectorTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
