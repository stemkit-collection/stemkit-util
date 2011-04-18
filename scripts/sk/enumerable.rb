# vim: set sw=2:

module SK
  module Enumerable
    include ::Enumerable

    class << self
      def append_features(other)
        instance_methods(false).each do |_method|
          next unless other.instance_methods.include?(_method)
          raise "#{self.name}: method #{_method.inspect} already defined for #{other.name}" 
        end

        super
      end

      def make(args)
        args.extend self
      end

      def transform_with(item, action, &block)
        if Hash === action
          action.map { |_action, _cascade|
            method, *args = Array(_action)

            Hash[ 
              method.to_s.intern => SK::Enumerable.make(item.send(method, *args)).map_with(*Array(*_cascade), &block) 
            ]
          }.first
        else
          value = item.send *Array(action)
          block_given? ? yield(value) : value
        end
      end

      def hash_aware_map(item)
        if Hash === item
          item.map { |_key, _value|
            yield [ _key, _value ]
          }
        else
          item.map { |_item|
            yield [ _item ]
          }
        end
      end
    end

    def unbox(*args)
      args = [ Array ] if args.empty?
      result = []

      each do |_item|
        case _item
          when *args
            result.concat SK::Enumerable.hash_aware_map(_item) { |_entries|
              _entries.size == 2 ? Hash[ _entries.first => _entries.last ] : _entries.first
            }
          else result.push _item
        end
      end

      result
    end

    def map_with(*args, &block) 
      actions = SK::Enumerable.make(args).unbox(Hash)
      SK::Enumerable.make actions.empty? ? map(&block) : begin
        map { |_item|
          actions.size == 1 ? SK::Enumerable.transform_with(_item, *actions, &block) : actions.map { |_action|
            SK::Enumerable.transform_with(_item, _action, &block)
          }
        }
      end
    end

    alias_method :collect_with, :map_with
  end
end

if $0 == __FILE__
  require 'tsc/dataset.rb'

  require 'test/unit'
  require 'mocha'
  require 'stubba'

  module SK
    class EnumerableTest < Test::Unit::TestCase
      def test_simple
        assert_equal [ "1", "2", "3" ], array(1, 2, 3).map_with(:to_s)
        assert_equal [ "AAA", "BBB" ], array("  aaa   ", "bbb").map_with(:upcase).map_with(:strip)
      end

      def test_with_parameters
        assert_equal [ 'aDc', 'zcD' ], array('abc', 'zcb').map_with([ :tr, 'b', 'D' ])
      end

      def test_sequence
        assert_equal [ ['AAA', 3], ['CC', 2] ], array('aaa', 'cc').map_with(:upcase, :size)
      end

      def test_cascading
        systems = [
          TSC::Dataset[ 
            :name => :s1, :hosts => [
              TSC::Dataset[ :name => :h1 ], TSC::Dataset[ :name => :h2 ]
            ]
          ], 
          TSC::Dataset[ 
            :name => :s2, :hosts => [
              TSC::Dataset[ :name => :h3 ], TSC::Dataset[ :name => :h4 ]
            ]
          ]
        ]

        expected = [[:s1, {:hosts=>[:h1, :h2]}], [:s2, {:hosts=>[:h3, :h4]}]]
        assert_equal expected, array(*systems).collect_with(:name, :hosts => :name)
      end

      def test_unbox
        assert_equal [ 1, 2, 3, 4, :a, [:b, :c] ], array([1, 2], [3, 4], :a, [[:b,:c]]).unbox
      end

      def test_unbox_keep_hashes
        assert_equal [ 1, 2, { 2=>3, 4=>5 }, "aa" ], array([1, 2], { 2=>3, 4=>5 }, "aa").unbox
      end

      def test_unbox_hash_only
        assert_equal [ [ 1, 2 ], { 2=>3 }, { 4=>5 }, "aa" ], array([1, 2], { 2=>3, 4=>5 }, "aa").unbox(Hash)
      end

      def setup
      end

      private
      #######

      def array(*args)
        SK::Enumerable.make args
      end
    end
  end
end
