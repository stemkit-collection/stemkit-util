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
    end

    def in_a_thread(&block)
      ready = false
      thread = Thread.new Thread.current do |_parent|
        begin
          localstore[:internal] = true
          ready = true

          block.call _parent
        rescue Exception => error
          case error
            when SK::Executor::Exit
            else
              unless @params.ignore
                if @params.relay 
                  _parent.raise TSC::Error.new(error)
                else
                  $stderr.puts TSC::Error.textualize(error, :backtrace => @params.verbose )
                end
              end
          end
        end
      end

      sleep 0.01 until ready
      add_thread thread
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
      terminate @group.list.map
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
        }
        _thread.raise Timeout::Error, "#{delta} exceeds #{tolerance}"
      end
    end

    private
    #######

    def localstore(thread = nil)
      (thread || Thread.current)[@tag] ||= Hash.new 
    end

    def terminate(threads)
      threads.each do |_thread|
        _thread.raise(Exit) if _thread.alive?

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

      def setup
        @executor = Executor.new
      end

      def teardown
        @executor.reset
      end
    end
  end
end
