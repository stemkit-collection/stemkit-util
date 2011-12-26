=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'yaml'
require 'tsc/dataset.rb'

require 'sk/config/data.rb'
require 'sk/config/data-interpolator.rb'
require 'sk/config/uproot-locator.rb'
require 'sk/config/home-locator.rb'

module SK
  module Config
    class Collector
      DEFAULTS = {
        :uproot => false,
        :home => false,
        :spot => '.'
      }
      def initialize(attributor = nil)
        @attributor = attributor
      end

      def collect(name, options = {})
        TSC::Dataset.new(DEFAULTS).update(options).tap { |_options|
          locator(name, _options).invoke(self)
          break config
        }
      end

      def process(content, location)
        registry[location] ||= begin
          Hash[ (YAML.parse(content) || self).transform ].tap { |_hash|
            config.update interpolator(location).transform(_hash)
          }
        end
      end

      def config
        @config ||= SK::Config::Data.new
      end

      def transform
        Hash.new
      end

      private
      #######

      def interpolator(location)
        SK::Config::DataInterpolator.new(location, @attributor && @attributor.config_attributes(location))
      end

      def registry
        @registry ||= {}
      end

      def locator(name, options)
        (options.uproot ? SK::Config::UprootLocator : SK::Config::SpotLocator).tap { |_class|
          return _class.new :item => name, :spot => options.spot, :locator => home_locator(name, options)
        }
      end

      def home_locator(name, options)
        SK::Config::HomeLocator.new(:item => String === options.home ? options.home : name) if options.home
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  p SK::Config::Collector.new(nil).collect('.buildrc', :uproot => true, :home => true).to_hash

  module SK
    module Config
      class CollectorTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
