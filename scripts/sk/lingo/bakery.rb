=begin
  vim: set sw=2:
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/item.rb'
require 'sk/lingo/baker.rb'

module SK
  module Lingo
    class Bakery
      attr_reader :options, :location, :undo

      def initialize(options, location, undo)
        @options = options
        @location = location
        @undo = undo
      end

      def make(item)
        process SK::Lingo::Item.new(item, options)
      end

      def process(item)
        return Baker.find(options.target).new(self).accept(item).call if options.target?
    
        processors = Baker.map { |_baker|
          _baker.new(self).accept(item)
        }.compact

        raise 'Unspecified target language, use option --target' unless processors.size == 1
        
        processors.first.call
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  SK::Lingo::Baker.each {}
  
  module SK
    module Lingo
      class BakeryTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
