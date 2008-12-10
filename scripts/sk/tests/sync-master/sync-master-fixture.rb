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

      def setup
        @depot = []
        @executor = SK::Executor.new
      end

      def teardown
        @lock = nil
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
