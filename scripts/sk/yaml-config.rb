=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'yaml'
require 'tsc/errors.rb'

module SK
  class YamlConfig
    class ParseError < TSC::Error
      def initilize(*args)
        error, location = *args.flatten.compact
        super locaiton ? "Error parsing #{location.inspect}" : "Parse error", error
      end
    end

    attr_reader :data

    def initialize(locator)
      @data = {}
      locator.invoke(self)
    end

    def process(data, location)
      begin
        @data.update Hash[ (YAML.parse(data) || self).transform ]
      rescue => original
        raise ParseError, [ original, location ]
      end
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

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    class YamlConfigTest < Test::Unit::TestCase
      def setup
      end
      
      def teardown
      end
    end
  end
end
