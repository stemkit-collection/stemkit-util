# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'timeout'
require 'tsc/errors.rb'
require 'tsc/launch.rb'
require 'thread'

module SK
  class Executor
    class Exit < Exception
    end

    DEFAULTS = { :tag => :sk, :relay => false }

    def initialize(params = {})
      params = DEFAULTS.merge(params)
      @tag = "#{params[:tag]}-#{object_id}"
      @relay = params[:relay]

      @transients = []
      @lock = Mutex.new
      @group = ThreadGroup.new
    end

    def in_a_thread(&block)
      add_thread Thread.new(Thread.current) { |_parent|
        localstore[:internal] = true
        TSC::Error.on_error(block, [ _parent ], Exception) do |_exception|
          case _exception
            when SK::Executor::Exit
            else
              if @relay 
                _parent.raise TSC::Error.new(_exception)
              else
                puts TSC::Error.textualize(_exception)
                raise
              end
          end
        end
      }
    end

    def threads
      @group.list
    end

    def add_thread(thread)
      @group.add thread
      thread
    end

    def join
      while thread = @group.list.first
        thread.join
      end
    end
    
    def reset
      terminate_threads if @group

      @transients = nil
      @lock = nil
      @group = nil
    end

    def terminate_threads
      @group.list.map.each do |_thread|
        # It is a quick workaround for JRuby, where Thread#exit does not
        # invoke ensure blocks. However, it may be good enough as a general
        # fix, as I cannot see any other good way to terminate properly
        # external threads (not managed).
        #
        # localstore(_thread)[:internal] ? _thread.raise(Exit) : _thread.exit
        _thread.raise(Exit)
        Thread.pass
      end
    end

    def timeout(seconds)
      return unless block_given?

      localstore[:timeout] = [ Time.now.to_i, seconds ]
      @lock.synchronize {
        @transients.push Thread.current
      }
      begin
        yield
      ensure
        localstore.delete(:timeout)
        @lock.synchronize {
          @transients.delete Thread.current
        }
      end
    end

    def start_timeout_enforcer(interval = 10, &block)
      in_a_thread do 
        localstore[:enforcer] = true

        loop do
          sleep(interval)
          block.call if block
          enforce_timeouts
        end
      end
    end

    def stop_timeout_enforcer
      enforcer = @group.list.find { |_thread|
        localstore(_thread)[:enforcer]
      }
      enforcer.raise Exit if enforcer && enforcer.alive?
      Thread.pass
    end

    private
    #######

    def localstore(thread = nil)
      (thread || Thread.current)[@tag] ||= Hash.new 
    end

    def enforce_timeouts
      threads = @lock.synchronize {
        @transients.clone
      }
      
      now = Time.now.to_i
      threads.each do |_thread|
        start, tolerance = localstore(_thread)[:timeout]
        next unless start
        delta = now - start
        next if delta < tolerance

        @lock.synchronize {
          @transients.delete _thread
        }
        _thread.raise Timeout::Error, "#{delta} exceeds #{tolerance}"
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  module SK
    class ExecutorTest < Test::Unit::TestCase
      attr_reader :executor

      def test_idle
        assert_equal 0, executor.threads.size
      end

      def test_internal_threads
        executor.in_a_thread do
          sleep 60
        end

        executor.in_a_thread do
          sleep 60
        end

        assert_equal 2, executor.threads.size
        executor.terminate_threads
        assert_equal 0, executor.threads.size
      end

      def test_join
        executor.in_a_thread do
          sleep 1
        end

        executor.in_a_thread do
          sleep 1.5
        end

        executor.in_a_thread do
          sleep 2
        end

        assert_equal 3, executor.threads.size
        timeout 3 do
          executor.join
        end
        assert_equal 0, executor.threads.size
      end

      def test_timeout_enforcer_start_stop
        assert_equal 0, executor.threads.size
        executor.start_timeout_enforcer(1)
        assert_equal 1, executor.threads.size
        sleep 2
        assert_equal 1, executor.threads.size
        executor.stop_timeout_enforcer
        assert_equal 0, executor.threads.size
      end

      def test_timeout_returns_block_value
        result = executor.timeout 2 do 
           "abcd"
        end

        assert_equal "abcd", result
      end

      def test_timeout_enforcement
        executor.start_timeout_enforcer(1)
        assert_raises Timeout::Error do
          executor.timeout 1 do
            sleep 3
          end
        end
      end

      def test_external_threads
        error = nil
        executor.add_thread Thread.new {
          begin
          sleep 10
          rescue Exception => error
          end
        }
        assert_equal 1, executor.threads.size
        executor.terminate_threads
        assert_equal 0, executor.threads.size
        assert_instance_of SK::Executor::Exit, error
      end

      def setup
        @executor = Executor.new
      end

      def teardown
        @executor.reset
      end
    end
  end
end
