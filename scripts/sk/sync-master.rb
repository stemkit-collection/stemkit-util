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

  module SK
    class SyncMasterTest < Test::Unit::TestCase
      attr_reader :lock

      def test_synchronize
        lock.synchronize do
          assert true
        end
      end

      def setup
        @lock = SyncMaster.new
      end
    end
  end
end
