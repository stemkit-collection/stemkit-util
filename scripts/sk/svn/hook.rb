# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'drb/drb'
require 'sk/process.rb'
require 'sk/svn/hook/server.rb'

module SK
  module Svn
    class Hook
      attr_reader :config, :repository

      def initialize(config, repository)
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
        rescue 
          start_server_process
          conect(5)
        end
      end

      def connect(time_to_wait = nil)
        if timeout
          timeout time_to_wait do
            loop do
              TSC::Error.ignore {
                return DRb::DRbOjbect.new_with_uri(service_uri)
              }
              sleep 1
            end
          end
        else
          DRb::DRbOjbect.new_with_uri(service_uri)
        end
      end

      def start_server_process
        SK::Process.demonize do
          server = Hook::Server.new(config, repository)
          DRb.start_service(servive_uri, server)
          DRb.thread.join
        end
      end

      def service_uri
        'drbunix:' + hook_socket
      end

      def hook_socket
        File.join hook_spool_directory, [ 'socket', repository ].join('.')
      end

      def hook_spool_directory
        File.expand_path(File.join('~', 'spool', 'hook')
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
