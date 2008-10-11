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

      def flatten_hash_entries(*args)
        result = []

        args.each do |_action|
          if Hash === _action
            _action.each_pair do |_key, _value|
              result << Hash[ _key => _value ]
            end
          else
            result << _action
          end
        end

        result
      end
    end

    def map_with(*args, &block) 
      actions = SK::Enumerable.flatten_hash_entries(*args)
      result = actions.empty? ? map(&block) : begin
        map { |_item|
          processor = proc { |_action|
            if Hash === _action
              entry = Array(_action).first
              action = Array(entry.first)
              Hash[ 
                action.first.to_s.intern => _item.send(*action).extend(SK::Enumerable).map_with(*Array(entry.last), &block) 
              ]
            else
              value = _item.send *Array(_action)
              block_given? ? yield(value) : value
            end
          }
          actions.size == 1 ? processor.call(actions.first) : actions.map(&processor)
        }
      end
      result.extend SK::Enumerable
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
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
        assert_equal expected, array(*systems).map_with(:name, :hosts => :name)
      end

      def setup
      end

      private
      #######

      def array(*args)
        [ *args ].extend SK::Enumerable
      end
    end
  end
end
