# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

require 'tsc/dataset.rb'

module SK
  class SyncMaster
    class DataReady < Exception
    end

    class Error < Exception
    end

    class TimeoutError < Error
      def initialize(timeout)
        super "Waiting for too long (#{timeout.inspect} exceeded)"
      end
    end

    class TooManyWaitersError < Error
      def initialize(*args)
        super "Too many waiters"
      end
    end

    class IllegalStateError < Error
      def initialize(*args)
        super "Should never get here normally"
      end
    end

    class NotOwnerError < Error
      def initialize(*args)
        super "Current thread not lock owner"
      end
    end

    def initialize(params = {})
      defaults = {
        :capacity => nil,
        :locker => nil,
        :wakeall => true
      }
      @config = TSC::Dataset[defaults].update params

      @lock = (@config.locker || default_locker).new
      @waiters = []
      @owner = nil

      self.capacity = @config.capacity
    end

    def default_locker
      if RUBY_PLATFORM == 'java'
        java.util.concurrent.locks.ReentrantLock
      else
        require 'sync'
        Sync
      end
    end

    def waiters_in_queue
	  @waiters.size
	end

    def capacity=(value)
      @capacity = value && [ value.to_i, 1 ].max
    end

    def wakeall=(state)
      @config.wakeall = state
    end

    def locked?
      @lock.locked?
    end

    def synchronize(blocking = true, &block)
      loop do
        begin
          timeout = catch :wait do
            if blocking
              @lock.lock
            else
              return false unless @lock.try_lock
            end

            begin
              @owner = Thread.current
              return block.call(self)
            ensure
              @owner = nil
              @lock.unlock
            end
          end

          if timeout
            sleep [ timeout.to_i, 0 ].max
            raise TimeoutError, timeout
          end

          Thread.stop 
          raise IllegalStateError

        rescue DataReady
        end
      end
    end

    def ensure(condition, timeout = nil, &block)
      ensure_lock_owned

      unless condition
        block.call if block

        unless @waiters.include? Thread.current
          raise TooManyWaitersError if @capacity && @waiters.size >= @capacity
          @waiters.unshift Thread.current 
        end

        throw :wait, timeout 
      end
    end

    def announce
      ensure_lock_owned

      until @waiters.empty?
        @waiters.pop.raise DataReady 
        break unless @config.wakeall
      end
    end

    def owner?
      @owner == Thread.current
    end

    private
    #######

    def ensure_lock_owned
      raise NotOwnerError unless owner?
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'sk/tests/sync-master-tester.rb'

  module SK
    class SyncMasterTest < Test::Unit::TestCase
      include SK::Tests::SyncMasterTester

      def lock
        @lock ||= SyncMaster.new
      end

      def setup
        super
      end
    end
  end
end
