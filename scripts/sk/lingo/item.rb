=begin
  vim: set sw=2:
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'pathname'
require 'tsc/dataset.rb'

module SK
  module Lingo
    class Item < TSC::Dataset
      def initialize(entry, options)
        super :location => nil, :name => nil, :namespace => nil, :extension => nil, :forced_namespace => false
        path = Pathname.new(entry).cleanpath

        name, extension = path.to_s.scan(%r{^(.+?)(?:[.]([^.]+))?$}).first
        components = split_namespace(name).compact

        specified_namespace = split_namespace(options.namespace)

        self.name = components.pop
        self.location = components
        self.extension = extension
        self.namespace = begin
          specified_namespace.compact.empty? ? components : begin
            self.forced_namespace = true
            [ specified_namespace, (components unless specified_namespace.last) ].flatten.compact
          end
        end
      end

      private
      #######
      
      def split_namespace(namespace)
        namespace.to_s.split(%r{[:/.]+}, -1).map { |_component|
          component = _component.strip
          component.empty? ? nil : component
        }
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  require 'tsc/dataset.rb'

  module SK
    module Lingo
      class ItemTest < Test::Unit::TestCase
        attr_reader :options

        def test_simple_name_specified_namespace
          item = SK::Lingo::Item.new 'ccc.java', TSC::Dataset[ :namespace => 'aaa.bbb' ]

          assert_equal 'ccc', item.name
          assert_equal 'java', item.extension
          assert_equal [ 'aaa', 'bbb' ], item.namespace
          assert_equal [], item.location
        end

        def test_simple_name_no_specified_namespace
          item = SK::Lingo::Item.new 'ccc.java', TSC::Dataset[ :namespace => nil ]

          assert_equal 'ccc', item.name
          assert_equal 'java', item.extension
          assert_equal [], item.namespace
          assert_equal [], item.location
        end

        def test_simple_name_no_extension
          item = SK::Lingo::Item.new 'ccc', TSC::Dataset[ :namespace => nil ]
          
          assert_equal 'ccc', item.name
          assert_equal nil, item.extension
          assert_equal [], item.namespace
          assert_equal [], item.location
        end

        def test_simple_name_no_extension_specified_namespace_with_empty_components
          item = SK::Lingo::Item.new 'ccc', TSC::Dataset[ :namespace => 'aaa.bbb///ccc::::ddd.' ]
          
          assert_equal 'ccc', item.name
          assert_equal nil, item.extension
          assert_equal [ 'aaa', 'bbb', 'ccc', 'ddd' ], item.namespace
          assert_equal [], item.location
        end

        def test_component_name_no_specified_namespace
          item = SK::Lingo::Item.new 'a/b.c::d.ccc.z', TSC::Dataset[ :namespace => nil ]
          
          assert_equal 'ccc', item.name
          assert_equal 'z', item.extension
          assert_equal false, item.forced_namespace?
          assert_equal [ 'a', 'b', 'c', 'd' ], item.namespace
          assert_equal [ 'a', 'b', 'c', 'd' ], item.location
        end

        def test_component_name_specified_namespace_overrides
          item = SK::Lingo::Item.new 'a/b.c::d.ccc.z', TSC::Dataset[ :namespace => "uu::oo" ]
          
          assert_equal 'ccc', item.name
          assert_equal 'z', item.extension
          assert_equal true, item.forced_namespace?
          assert_equal [ 'uu', 'oo'], item.namespace
          assert_equal [ 'a', 'b', 'c', 'd' ], item.location
        end

        def test_component_name_specified_namespace_joins
          item = SK::Lingo::Item.new 'a/b/ccc.z', TSC::Dataset[ :namespace => "uu::oo::" ]
          
          assert_equal 'ccc', item.name
          assert_equal 'z', item.extension
          assert_equal true, item.forced_namespace?
          assert_equal [ 'uu', 'oo', 'a', 'b' ], item.namespace
          assert_equal [ 'a', 'b' ], item.location
        end

        def setup
          @options = mock 'options'
        end
      end
    end
  end
end
