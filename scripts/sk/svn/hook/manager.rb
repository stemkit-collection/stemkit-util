# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'drb/drb'
require 'timeout'

require 'sk/process.rb'
require 'sk/svn/hook/server.rb'
require 'sk/svn/hook/error-mailer.rb'
require 'tsc/ftools.rb'

module SK
  module Svn
    module Hook
      class Manager
        attr_reader :name, :config, :repository

        include ErrorMailer

        def initialize(name, config, repository)
          @name = name
          @config = config
          @repository = repository
          @server = connect_to_server
        end

        def process(revision)
          @server.process(revision)
        end

        private
        #######

        def connect_to_server
          begin
            connect
          rescue DRb::DRbConnError => exception
            start_server_process
            connect(5)
          end
        end

        def connect(time_to_wait = nil)
          if time_to_wait
            timeout time_to_wait do
              loop do
                TSC::Error.ignore(DRb::DRbConnError) {
                  return setup_remote_object
                }
                sleep 1
              end
            end
          else
            setup_remote_object
          end
        end

        def setup_remote_object
          remote = DRb::DRbObject.new_with_uri(service_uri)
          remote.handshake

          remote
        end

        def start_server_process
          File.rm_f hook_socket
          File.makedirs hook_spool_directory

          SK::Process.demonize(false) do
            File.open(logfile, 'a') do |_io|
              $stdout.reopen _io
              $stderr.reopen _io
            end

            Thread.abort_on_exception = true

            report_error('Server') {
              server = Hook::Server.new(name, config, repository)
              DRb.start_service(service_uri, server)
              DRb.thread.join
            }
            exit
          end
        end

        def logfile
          @logfile ||= File.expand_path "~/logs/#{name}.#{repository}.log"
        end

        def service_uri
          'drbunix:' + hook_socket
        end

        def hook_socket
          File.join hook_spool_directory, "socket.#{repository}"
        end

        def hook_spool_directory
          File.expand_path '~/spool/hook'
        end

      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module SK
    module Svn
      class HookTest < Test::Unit::TestCase
        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
