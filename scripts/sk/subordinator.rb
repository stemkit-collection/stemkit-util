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
    attr_reader :entries

    class CycleError < RuntimeError
      def initialize(entry)
        super "Cyclic dependency detected (#{entry.inspect})"
      end
    end

    def initialize(*items)
      @entries = []

      normalize_and_order items, Hash.new { |_h, _k|
        _h[_k] = Set.new
      }
    end

    class << self
      def master_to_slave(*items)
        new(*items)
      end

      def slave_to_master(*items)
        master_to_slave *items.map { |_item|
          Array(Hash[*_item]).map { |_entry|
            _entry.reverse
          }
        }
      end
    end

    def slaves
      @entries.map { |_entry|
        Array(_entry.last)
      }.flatten.sort
    end

    def masters
      @entries.map { |_entry|
        _entry.first
      }.sort
    end

    def lineup
      @entries.transpose.flatten.map { |_item| Array(_item).sort }.flatten.uniq
    end

    private
    #######

    def normalize_and_order items, hash
      items.each do |_item|
        Hash[*_item.flatten].each do |_master, _slave|
          hash[_master] << _slave
        end
      end

      order Array(hash)
    end

    def order(array)
      processed = Hash.new { |_h, _k|
        _h[_k] = 0
      }
      while entry = array.shift
        if array.detect { |_item| _item.last.include? entry.first }
          raise CycleError, entry if processed[entry]  > 1
          processed[entry] += 1

          array << entry
        else
          @entries << entry
        end
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  require 'timeout'

  class ::Symbol
    def <=>(other)
      self.to_s <=> other.to_s
    end
  end

  module SK
    class SubordinatorTest < Test::Unit::TestCase
      attr_reader :array

      def test_slaves
        100.times do
          assert_equal [3, 4, 5, 6, 7, 8, 9, 17, 18, 19], Subordinator.slave_to_master(*randomize(array)).slaves
        end
      end

      def test_masters
        100.times do
          assert_equal [ 1, 3, 5, 6 ], Subordinator.slave_to_master(*randomize(array)).masters
        end
      end

      def randomize(array)
        array.sort_by {
          rand
        }
      end

      def test_cycle_detection
        a = [ 
          [ 1, 2 ],
          [ 2, 1 ]
        ]
        timeout 3 do 
          assert_raises Subordinator::CycleError do 
            Subordinator.slave_to_master(*a).masters
          end
        end
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
          assert_equal [ 16973, 16975, 16976, 16977, 17217], Subordinator.slave_to_master(*randomize(a)).slaves
        end
      end

      def test_strings
        h = Hash[
          :gena => :felix,
          :dennis => :gena,
          :vika => :gena,
          :felix => :klim
        ]
        assert_equal [ :klim, :felix, :gena, :dennis, :vika ], Subordinator.slave_to_master(*h).lineup
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
