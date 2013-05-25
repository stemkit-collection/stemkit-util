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
require 'tsc/dataset.rb'
require 'thread'

module SK
  class Executor
    class Exit < Exception
    end

    DEFAULTS = {
      :tag => :sk,
      :relay => false,
      :verbose => false,
      :ignore => false,
      :terminate_tolerance => 5
    }
    def initialize(args = {})
      @params = TSC::Dataset[DEFAULTS].update(args)

      @tag = "#{@params.tag}-#{object_id}"
      @terminate_tolerance = @params.terminate_tolerance.to_s.to_i

      @transients = []
      @lock = Mutex.new
      @group = ThreadGroup.new

      preserve_if_native_java_thread Thread.current
    end

    def perform(options = {}, &block)
      params = TSC::Dataset[ :sync => false, :timeout => nil ].update(options)
      ready = false

      thread = Thread.new Thread.current do |_parent|
        handle_errors do
          localstore[:internal] = true
          localstore[:parent] = _parent
          preserve_if_native_java_thread Thread.current
          ready = true

          if params.timeout
            self.timeout *params.timeout do
              block.call _parent
            end
          else
            block.call _parent
          end
        end
      end

      sleep 0.01 until ready
      add_thread thread

      thread.join if params.sync
      thread
    end

    def threads
      @group.list
    end

    def add_thread(thread)
      @group.add thread
      thread
    end

    def join(options = {})
      TSC::Dataset[ :external => true ].update(options).external.tap do |_external|
        @group.list.each do |_thread|
          next if localstore(_thread)[:enforcer]
          _thread.join if localstore(_thread)[:internal] or _external
        end
      end

      stop_timeout_enforcer
    end

    def reset
      terminate_threads if @group

      @transients = nil
      @lock = nil
      @group = nil
    end

    def terminate_threads
      terminate @group.list.clone
    end

    def timeout(seconds, options = {}, &block)
      return unless block
      return unless seconds

      params = TSC::Dataset[ :ignore => false ].update(options)
      localstore[:timeout] = [ Time.now.to_i, seconds ]

      @lock.synchronize {
        @transients.push Thread.current
      }

      begin
        delay_java_native_interrupt_if_any params.ignore == false ? block : proc {
          TSC::Error.ignore Timeout::Error do
            block.call
          end
        }
      ensure
        @lock.synchronize {
          localstore.delete :timeout
          @transients.delete Thread.current
        }
      end
    end

    def start_timeout_enforcer(interval = 10, &block)
      in_a_thread do
        localstore[:enforcer] = true

        loop do
          sleep interval

          handle_errors do
            block.call if block
            enforce_timeouts
          end
        end
      end
    end

    def stop_timeout_enforcer
      terminate @group.list.select { |_thread|
        localstore(_thread)[:enforcer]
      }
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

          interrupt_if_native_java_thread(_thread)
          _thread.raise Timeout::Error, "#{delta} exceeds #{tolerance}"
        }
      end
    end

    alias_method :in_a_thread, :perform

    private
    #######

    def delay_java_native_interrupt_if_any(block)
      begin
        block.call
      rescue Exception => error
        case error
          when native_exception_class
            sleep 0.5 if error.cause.class == java.lang.InterruptedException
        end

        raise
      end
    end

    def handle_errors(&block)
      begin
        delay_java_native_interrupt_if_any block
      rescue Exception => error
        catch :done do
          case error
            when SK::Executor::Exit
              throw :done
          end

          unless @params.ignore
            if @params.relay
              localstore[:parent].raise TSC::Error.new(error)
            else
              $stderr.puts TSC::Error.textualize(error, :backtrace => @params.verbose )
            end
          end
        end
      end
    end

    def preserve_if_native_java_thread(thread)
      return unless jruby?
      localstore(thread)[:java] = java.lang.Thread.currentThread
    end

    def native_exception_class
      jruby? ? NativeException : nil.class
    end

    def interrupt_if_native_java_thread(thread)
      (localstore(thread)[:java] or return).interrupt if jruby?
      sleep 0.1
    end

    def stop_if_alive(thread)
      return unless thread.alive?

      interrupt_if_native_java_thread(thread)
      thread.raise(Exit)
    end

    def jruby?
      RUBY_PLATFORM == 'java'
    end

    def localstore(thread = nil)
      (thread || Thread.current)[@tag] ||= Hash.new
    end

    def terminate(*threads)
      threads.flatten.compact.each do |_thread|
        stop_if_alive _thread

        ready = false
        guard = Thread.new Thread.current do |_master|
          TSC::Error.ignore Exit do
            ready = true
            sleep @terminate_tolerance
            _master.raise Timeout::Error, "Terminate tolerance exceeded (#{@terminate_tolerance})"
          end
        end

        _thread.join

        sleep 0.01 until ready
        guard.raise Exit
        guard.join
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

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

        executor.perform do
          sleep 60
        end

        assert_equal 2, executor.threads.size
        executor.terminate_threads
        assert_equal 0, executor.threads.size
      end

      def test_join
        executor.perform do
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

      def test_termination_tolerance
        executor = Executor.new :terminate_tolerance => 2
        executor.in_a_thread do
          loop do
            begin
              sleep 5
              break
            rescue Exception
            end
          end
        end

        sleep 1
        error = assert_raises Timeout::Error do
          executor.terminate_threads
        end
        assert_equal "Terminate tolerance exceeded (2)", error.message
      end

      def test_startup
        assert_equal 0, executor.threads.size
      end

      def test_in_ruby_terminate
        t = executor.in_a_thread do
          sleep 60
        end
        sleep 1
        assert_equal 1, executor.threads.size
        assert_equal true, t.alive?

        executor.terminate_threads

        sleep 1
        assert_equal 0, executor.threads.size
        assert_equal false, t.alive?
      end

      if RUBY_PLATFORM == 'java'
        def test_in_java_terminate
          t = executor.in_a_thread do
            java.lang.Thread.sleep(60000)
          end
          sleep 1
          assert_equal 1, executor.threads.size
          assert_equal true, t.alive?

          executor.terminate_threads

          sleep 1
          assert_equal 0, executor.threads.size
          assert_equal false, t.alive?
        end
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
