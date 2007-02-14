# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'timeout'
require 'tsc/synchro-queue.rb'

require 'sk/svn/revision-look.rb'
require 'sk/svn/mail-notifier.rb'
require 'sk/svn/hook/error-mailer.rb'
require 'sk/svn/hook/plugin/manager.rb'

module SK
  module Svn
    module Hook
      class Server
        attr_reader :name, :config, :repository, :manager

        include ErrorMailer

        def initialize(name, config, repository)
          @name = name
          @config = config
          @repository = repository
          @queue = TSC::SynchroQueue.new(true)
          @manager = Plugin::Manager.new(self, SK::Svn::MailNotifier)

          @processor = Thread.new do
            begin
              report_error('Hook server') {
                begin
                  $stderr.puts "#{Time.now} - STARTED (pid=#{::Process.pid}, timeout=#{config.request_wait_timeout})"
                  loop do
                    invoke_plugins_for @queue.get(config.request_wait_timeout)
                  end
                rescue TSC::OperationFailed
                end
              }
              exit
            ensure
              $stderr.puts "#{Time.now} - FINISHED (pid=#{::Process.pid})"
            end
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
          $stderr.puts "#{Time.now} - Revision #{revision} started"

          begin
            manager.invoke SK::Svn::RevisionLook.new(config.repository_path(repository), revision)
          ensure
            $stderr.puts "#{Time.now} - Revision #{revision} finished"
          end
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
