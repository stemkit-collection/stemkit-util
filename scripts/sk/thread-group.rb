=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

module SK
  class ThreadGroup
    def initialize(tag = :sk)
      @tag = "#{tag}-#{objectid}"
      @threads_to_timeout = []
      @lock = Mutex.new
    end

    def timeout(seconds)
      return unless block_given?

      localstore[:timeout] = [ Time.now.to_i, seconds ]
      @lock.synchronize {
        @threads_to_timeout.push Thread.current
      }
      begin
        yield
      ensure
        localstore.delete(:timeout)
        @lock.synchronize {
          @threads_to_timeout.delete Thread.current
        }
      end
    end

    def check_expiration
      threads = @lock.synchronize {
        @threads_to_timeout.clone
      }
      
      now = Time.now.to_i
      threads.each do |_thread|
        start, tolerance = localstore(_thread)[:timeout]
        next if (now - start) < tolerance

        @lock.synchronize {
          @threads_to_timeout.delete _thread
        }
        _thread.raise Timeout::Error, 'operation timed out'
      end
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
    class ThreadGroupTest < Test::Unit::TestCase
      def setup
      end
    end
  end
end
