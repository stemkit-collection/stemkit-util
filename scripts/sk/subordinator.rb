=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'set'

module SK
  class Subordinator
    def initialize(*entries)
      @hash = Hash.new { |_h, _k|
        _h[_k] = Set.new
      }
      entries.each do |_entry|
        Hash[*_entry.flatten].each do |_master, _slave|
          @hash[_master] << _slave
        end
      end
    end

    class << self
      def master_to_slave(*entries)
        new(*entries)
      end

      def slave_to_master(*entries)
        master_to_slave *entries.map { |_entry|
          Array(Hash[*_entry]).map { |_item|
            _item.reverse
          }
        }
      end
    end

    def dependents
      order.map { |_entry|
        Array(_entry.last).sort
      }.flatten
    end

    def order
      @hash.sort { |_e1, _e2|
        _e1[1].member?(_e2[0]) ? -1 : 1
      }
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    class SubordinatorTest < Test::Unit::TestCase
      attr_reader :array

      def test_dependents
        assert_equal [3, 4, 5, 6, 7, 8, 9, 17, 18, 19], Subordinator.slave_to_master(*array).dependents
      end

      def test_different_source_order_equal
        100.times do
          assert_equal Subordinator.slave_to_master(*randomized_array).dependents, Subordinator.slave_to_master(*randomized_array).dependents
        end
      end

      def randomized_array
        array.sort_by {
          rand
        }
      end

      def setup
        @array = [
          [ 7, 5 ],
          [ 8, 5 ],
          [ 5, 3 ],
          [ 9, 5 ],

          [ 17, 6 ],
          [ 18, 6 ],
          [ 19, 6 ],
          [ 3, 1 ],
          [ 4, 1 ],
          [ 6, 3 ],
        ]

      end
    end
  end
end
