# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/synchro-queue.rb'
require 'timeout'

module SK
  module Svn
    module Hook
      class Server
        attr_reader :name, :config, :repository

        def initialize(name, config, repository)
          @name = name
          @config = config
          @repository = repository
          @queue = TSC::SynchroQueue.new(true)

          @processor = Thread.new do 
            $stderr.puts "#{Time.now} - STARTED (pid=#{::Process.pid})"
            begin
              loop do
                invoke_plugins_for @queue.get(10)
              end
            rescue TSC::OperationFailed
            end
            $stderr.puts "#{Time.now} - FINISHED (pid=#{::Process.pid})"
            exit
          end
        end

        def handshake
          repository
        end

        def process(revision)
          @queue.put(revision)
        end

        private
        #######

        def invoke_plugins_for(revision)
          $stderr.puts "#{Time.now} - invoke_plugins_for(#{revision})"
          sleep 60
        end
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module SK
    module Svn
      module Hook
        class ServerTest < Test::Unit::TestCase
          def setup
          end
          
          def teardown
          end
        end
      end
    end
  end
end
