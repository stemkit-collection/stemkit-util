# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

require 'sync'

module SK
  class SyncMaster
    class DataReady < Exception
    end

    def initialize
      @lock = Sync.new
      @waiters = []
    end

    def synchronize(&block)
      loop do
        begin
          timeout = catch :wait do
            @lock.synchronize do
              return block.call(self)
            end
          end
          sleep [ timeout, 1 ].max
          next if timeout.zero?

          raise "Waiting for too long (#{timeout} exceeded)"
        rescue DataReady
        end
      end
    end

    def ensure(condition, timeout = 0)
      unless condition
        @waiters.unshift Thread.current
        throw :wait, timeout
      end
    end

    def announce
      @waiters.pop.raise DataReady unless @waiters.empty?
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  require 'sk/executor.rb'
  require 'enumerator'

  module SK
    class SyncMasterTest < Test::Unit::TestCase
      attr_reader :lock, :executor, :depot

      def test_populate_with_lock_must_succeed
        assert make_slices(1000, 500).all? { |_item|
          _item == 1
        }
      end

      def test_populate_no_lock_must_fail
        lock.expects(:synchronize).at_least_once.yields
        assert make_slices(10, 5).any? { |_item|
          _item != 1
        }
      end

      def make_slices(runs, amount)
        populate(runs, amount, 1)
        populate(runs, amount, 2)
        populate(runs, amount, 3)

        executor.join
        assert_equal runs * amount * 3, depot.size

        slices = depot.enum_slice(amount).map
        assert_equal runs * 3, slices.size

        slices.map { |_slice|
          _slice.uniq.size
        }
      end

      def populate(runs, amount, data)
        executor.in_a_thread do
          runs.times do
            lock.synchronize do
              amount.times do 
                Thread.pass
                depot.push data
              end
            end
          end
        end
      end

      def setup
        @depot = []
        @lock = SyncMaster.new
        @executor = SK::Executor.new
      end
    end
  end
end
