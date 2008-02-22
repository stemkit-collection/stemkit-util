=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'yaml'

module SK
  class YamlConfig
    attr_reader :data

    def initialize(locator)
      locator.invoke(self)
    end

    def process(data, location)
      @data = Hash[ (YAML.parse(data) || self).transform ]
    end

    def transform
      Hash[]
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
