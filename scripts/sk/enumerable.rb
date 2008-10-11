# vim: set sw=2:

module SK
  module Enumerable
    include ::Enumerable

    def self.append_features(other)
      instance_methods(false).each do |_method|
        next unless other.instance_methods.include?(_method)
        raise "#{self.name}: method #{_method.inspect} already defined for #{other.name}" 
      end

      super
    end

    def map_with(*actions, &block) 
      result = actions.empty? ? map(&block) : begin
        map { |_item|
          processor = proc { |_action|
            value = _item.send _action
            block_given? ? yield(value) : value
          }
          actions.size == 1 ? processor.call(actions.first) : actions.map(&processor)
        }
      end
      result.extend SK::Enumerable
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  module SK
    class EnumerableTest < Test::Unit::TestCase
      def test_simple
        assert_equal [ "1", "2", "3" ], array(1, 2, 3).map_with(:to_s)
        assert_equal [ "AAA", "BBB" ], array("  aaa   ", "bbb").map_with(:upcase).map_with(:strip)
      end

      def test_sequence
        assert_equal [ ['AAA', 3], ['CC', 2] ], array('aaa', 'cc').map_with(:upcase, :size)
      end

      def test_cascading
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
