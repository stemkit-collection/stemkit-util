=begin
  vim: set sw=2:
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'pathname'

module SK
  module Lingo
    class Item
      attr_reader :bakery, :location, :name, :namespace, :extension

      def initialize(entry, bakery)
        @bakery = bakery
        location, file = Pathname.new(entry).split

        name, extension = file.to_s.scan(%r{^(.+?)(?:[.]([^.]+))?$}).first
        namespace = split_namespace(name)

        @name = namespace.pop
        @location = location.cleanpath.to_s
        @namespace = specified_namespace(bakery.options).compact + namespace
        @extension = extension
      end

      private
      #######
      
      def specified_namespace(options)
        @specified_namespace ||= begin
          split_namespace options.namespace
        end
      end

      def split_namespace(namespace)
        namespace.to_s.split(%r{[:/.]+}).map { |_component|
          component = _component.strip
          component.empty? ? nil : component
        }
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  require 'tsc/dataset.rb'

  module SK
    module Lingo
      class ItemTest < Test::Unit::TestCase
        attr_reader :bakery

        def test_simple_name_specified_namespace
          bakery.expects(:options).returns TSC::Dataset[ :namespace => 'aaa.bbb' ]
          item = SK::Lingo::Item.new 'ccc.java', bakery

          assert_equal 'ccc', item.name
          assert_equal 'java', item.extension
          assert_equal [ 'aaa', 'bbb' ], item.namespace
          assert_equal '.', item.location
        end

        def test_simple_name_no_specified_namespace
          bakery.expects(:options).returns TSC::Dataset[ :namespace => nil ]
          item = SK::Lingo::Item.new 'ccc.java', bakery

          assert_equal 'ccc', item.name
          assert_equal 'java', item.extension
          assert_equal [], item.namespace
          assert_equal '.', item.location
        end

        def test_simple_name_no_extension
          bakery.expects(:options).returns TSC::Dataset[ :namespace => nil ]
          item = SK::Lingo::Item.new 'ccc', bakery
          
          assert_equal 'ccc', item.name
          assert_equal nil, item.extension
          assert_equal [], item.namespace
          assert_equal '.', item.location
        end

        def test_simple_name_no_extension_specified_namespace_with_empty_components
          bakery.expects(:options).returns TSC::Dataset[ :namespace => 'aaa.bbb///ccc::::ddd.' ]
          item = SK::Lingo::Item.new 'ccc', bakery
          
          assert_equal 'ccc', item.name
          assert_equal nil, item.extension
          assert_equal [ 'aaa', 'bbb', 'ccc', 'ddd' ], item.namespace
          assert_equal '.', item.location
        end

        def setup
          @bakery = mock('bakery')
        end
      end
    end
  end
end
