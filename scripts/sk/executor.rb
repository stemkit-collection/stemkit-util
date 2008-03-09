=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'timeout'
require 'tsc/errors.rb'

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
      @group.add Thread.new(Thread.current) { |_parent|
        TSC::Error.on_error(block, [ _parent ], Exception) do |_exception|
          case _exception
            when Exit
            else
              if @relay 
                _parent.raise TSC::Error.new(_exception)
              else
                puts TSC::Error.textualize(_exception)
              end
          end
        end
      }
    end

    def threads
      @group.list
    end

    def add_thread(thead)
      @group.add thread
    end

    def join
      while thread = @group.list.first
        thread.join
      end
    end
    
    def reset
      terminate_threads
    end

    def terminate_threads
      while thread = @group.list.first
        thread.raise Exit
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

    def enforce_timeouts
      threads = @lock.synchronize {
        @transients.clone
      }
      
      now = Time.now.to_i
      threads.each do |_thread|
        start, tolerance = localstore(_thread)[:timeout]
        next if (now - start) < tolerance

        @lock.synchronize {
          @transients.delete _thread
        }
        _thread.raise Timeout::Error, 'operation timed out'
      end
    end

    def start_timeout_enforcer(interval = 10)
      in_a_thread do 
        localstore[:enforcer] = true

        sleep(interval)
        enforce_timeouts
      end
    end

    def stop_timeout_enforcer
      enforcer = @group.list.find { |_thread|
        localstore(_thread)[:enforcer]
      }
      enforcer.raise Exit
    end

    private
    #######

    def localstore(thread = Thread.current)
      thread[@tag] ||= Hash.new 
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

      def test_local_thread
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

      def test_timeout
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
