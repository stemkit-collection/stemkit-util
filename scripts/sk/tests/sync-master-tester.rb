# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

require 'sk/executor.rb'

require 'enumerator'
require 'test/unit'
require 'mocha'
require 'stubba'

module SK
  module Tests
    module SyncMasterTester
      attr_reader :executor, :depot

      def test_populate_with_lock_must_succeed
        assert make_slices(10, 1000, 500).all? { |_item|
          _item == 1
        }
      end

      def NO_test_populate_no_lock_must_fail
        lock.expects(:synchronize).at_least_once.yields
        assert make_slices(2, 10, 5).any? { |_item|
          _item != 1
        }
      end

      def test_ensure_fails_if_not_owner
        assert_raises SyncMaster::NotOwnerError do
          lock.ensure true
        end
      end

      def test_anounce_fails_if_not_owner
        assert_raises SyncMaster::NotOwnerError do
          lock.announce
        end
      end

      def test_ensure
        executor.in_a_thread do
          loop do
            5.times do
              lock.synchronize do |_condition|
                depot.push 0
                _condition.announce
              end
              sleep 0.1
            end
            sleep 0.5
          end
        end

        registry = []
        lock.synchronize do |_condition|
          _condition.ensure depot.size >= 5, 1 do
            registry.push depot.size
          end
          assert_equal 5, depot.size
          assert_equal true, lock.owner?
          sleep 1
          assert_equal 5, depot.size
        end

        assert_equal [ 1, 2, 3, 4 ], registry
      end

      def test_ensure_timeout
        block_called = false
        assert_raises SyncMaster::TimeoutError do
          lock.synchronize do |_condition|
            _condition.ensure depot.size > 0, 1 do
              block_called = true
            end
          end
          assert_equal true, block_called
        end
      end

      def test_ensure_succeeds_immediatelly
        block_called = false
        assert_nothing_raised do
          lock.synchronize do |_condition|
            _condition.ensure depot.empty? do
              block_called = true
            end
          end
          assert_equal false, block_called
        end
      end

      def test_wakeall
        5.times do
          make_waking_thread
        end

        lock.synchronize do |_condition|
          depot.push nil
          _condition.announce
        end

        sleep 1
        assert_equal 6, depot.size
      end

      def test_wakeone
        lock.wakeall = false

        5.times do
          make_waking_thread
        end

        lock.synchronize do |_condition|
          depot.push nil
          _condition.announce
        end

        sleep 1
        assert_equal 2, depot.size
      end

      def test_capacity
        lock.capacity = 3

        make_waking_thread
        make_waking_thread
        make_waking_thread

        assert_raises SyncMaster::TooManyWaitersError do
          lock.synchronize do |_condition|
            _condition.ensure depot.empty? == false
          end
        end
      end

      if RUBY_PLATFORM == 'java'
        def test_non_blocking
          executor.in_a_thread {
            lock.synchronize(true) do
              sleep 2
            end
          }
          Thread.pass

          assert_equal true, lock.locked?
          assert_equal false, lock.synchronize(false) { "inside" }
          sleep 2
          assert_equal "inside", lock.synchronize(false) { "inside" }
        end
      end

      def setup
        @depot = []
        @executor = SK::Executor.new
      end

      def teardown
        executor.reset
      end

      def lock
        raise TSC::NotImplementedError, :lock
      end

      private
      #######

      def make_waking_thread
        executor.in_a_thread do
          lock.synchronize do |_condition|
            _condition.ensure depot.empty? == false, 5
            depot.push Thread.current.object_id
          end
        end
      end

      def make_slices(threads, runs, amount)
        threads.times do |_index|
          populate(runs, amount, _index)
        end

        executor.join
        assert_equal runs * amount * threads, depot.size

        slices = depot.enum_slice(amount).map
        assert_equal runs * threads, slices.size

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
    end
  end
end
