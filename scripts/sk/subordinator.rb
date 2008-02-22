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
      r = []
      a = Array(@hash)

      while item = a.shift
        if a.detect { |_entry| _entry.last.include? item.first }
          a << item
        else
          r << item
        end
      end

      r
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
        100.times do
          assert_equal [3, 4, 5, 6, 7, 8, 9, 17, 18, 19], Subordinator.slave_to_master(*randomize(array)).dependents
        end
      end

      def randomize(array)
        array.sort_by {
          rand
        }
      end

      def test_other
        a = [
          [ 16973,     1 ],
          [ 16975,     1 ],
          [ 16976, 16973 ],
          [ 16977, 16973 ],
          [ 17217, 16977 ],
        ]

        100.times do
          assert_equal [ 16973, 16975, 16976, 16977, 17217], Subordinator.slave_to_master(*randomize(a)).dependents
        end
      end

      def setup
        @array = [
          [ 3, 1 ],
          [ 4, 1 ],

          [ 6, 3 ],
          [ 5, 3 ],

          [ 7, 5 ],
          [ 8, 5 ],
          [ 9, 5 ],

          [ 17, 6 ],
          [ 18, 6 ],
          [ 19, 6 ],
        ]
      end
    end
  end
end

__END__
