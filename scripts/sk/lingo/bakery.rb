=begin
  vim: set sw=2:
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/baker.rb'
require 'pathname'

module SK
  module Lingo
    class Bakery
      attr_reader :options, :undo

      def initialize(options, undo)
        @options = options
        @undo = undo
      end

      def make(item)
        process normalize(item)
      end

      def process(item)
        return Baker.find(options.target).new(self).accept(item).call if options.target?
    
        processors = Baker.map { |_baker|
          _baker.new(self).accept(item)
        }.compact

        raise 'Unspecified target language, use option --target' unless processors.size == 1
        
        processors.first.call
      end

      private
      #######
      
      def normalize(item)
        name, extension = item.scan(%r{^(.+?)(?:[.](.+))?$}).first
        namespace = split_namespace(name)

        TSC::Dataset[ 
          :name => namespace.pop, 
          :namespace => global_namespace + namespace,
          :extension => extension
        ]
      end

      def global_namespace
        @global_namespace ||= begin
          split_namespace options['namespace']
        end
      end

      def split_namespace(namespace)
        namespace.to_s.split(%r{(?::+)|(?:[.])})
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
