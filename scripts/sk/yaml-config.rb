=begin
  vim: sw=2:
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'yaml'
require 'tsc/errors.rb'
require 'sk/config/data.rb'

module SK
  class YamlConfig
    class ParseError < TSC::Error
      def initilize(*args)
        error, location = *args.flatten.compact
        super locaiton ? "Error parsing #{location.inspect}" : "Parse error", error
      end
    end

    attr_reader :data

    def initialize(locator, options = {})
      @data = SK::Config::Data.new
      @options = options

      locator.invoke(self)
    end

    def process(data, location)
      begin
        @data.update Hash[ (YAML.parse(data) || self).transform ], @options
        locations << location
      rescue => original
        raise ParseError, [ original, location ]
      end
    end

    def locations
      @locations ||= []
    end

    def method_missing(name, *args)
      data.send name, *args
    end

    def transform
      Hash[]
    end

    class << self
      def [](locator)
        new locator
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    class YamlConfigTest < Test::Unit::TestCase
      attr_reader :locator

      def test_valid
        locator.expects(:invoke).with { |_processor|
          _processor.process("abc: zzz", "/tmp")
          true
        }
        config = SK::YamlConfig.new locator
        assert_equal Hash[ 'abc' => 'zzz' ], config.data
      end

      def test_parse_error
        locator.stubs(:invoke).with { |_processor|
          _processor.process("abc", "/tmp")
          true
        }
        assert_raises SK::YamlConfig::ParseError do
          config = SK::YamlConfig.new locator
        end
      end

      def setup
        @locator = mock('locator')
      end
    end
  end
end
