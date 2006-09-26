# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/synchro-queue.rb'
require 'sk/svn/look.rb'
require 'sk/svn/mail-notifier.rb'
require 'sk/svn/hook/error-mailer.rb'
require 'timeout'

module SK
  module Svn
    module Hook
      class Server
        attr_reader :name, :config, :repository

        include ErrorMailer

        def initialize(name, config, repository)
          @name = name
          @config = config
          @repository = repository
          @queue = TSC::SynchroQueue.new(true)

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
            info = SK::Svn::Look.new(config.repository_path(repository), revision)
            plugins.each do |_plugin|
              report_error('Plugin processing') {
                _plugin.process(info)
              }
            end
          ensure
            $stderr.puts "#{Time.now} - Revision #{revision} finished"
          end
        end

        def plugins
          @plugins ||= begin
            config.plugins(repository).map { |_plugin|
              load_plugin(_plugin)
            } + [ SK::Svn::MailNotifier ]
          end.compact.uniq.map { |_klass|
            instantiate_plugin(_klass)
          }.compact
        end

        def instantiate_plugin(plugin)
          report_error('Plugin instantiation') {
            return plugin.new(config)
          }
          nil
        end

        def load_plugin(spec)
          report_error("Plugin #{spec.inspect} load") {
            components = spec.split('::')
            require File.join(module_paths(components[0...-1]), class_file(components.last))

            return components.inject(Module) { |_module, _constant|
              _module.const_get(_constant)
            }
          }
          nil
        end

        def module_paths(names)
          names.map { |_name| 
            _name.downcase 
          }
        end

        def class_file(name)
          name.scan(%r{[A-Z][a-z0-9_]*}).map { |_c| _c.downcase }.join('-')
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
