=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky <bystr@mac.com>
=end

require 'pathname'
require 'sk/svn/repository.rb'
require 'tsc/dataset.rb'
require 'tsc/launch.rb'
require 'sk/ruby.rb'

module SK
  module Svn
    class Depot
      include SK::Ruby
      attr_reader :repositories

      DEFAULT_PARAMS = { :location => "~/depots", :listener => nil }

      def initialize(params = {})
        @params = TSC::Dataset.new(DEFAULT_PARAMS).update(normalize_params(params))
        @launcher = TSC::Launcher.new

        @params.listener ||= self

        @repositories = find_repository_folders(@params.location).map { |_folder|
          Repository.new self, :name => _folder.basename.to_s, :path => _folder
        }
      end

      def repository(name)
        @repositories.detect { |_repo|
          _repo.name == name
        }
      end

      def launch(*args)
        with TSC::Launcher.normalize_command_args(args) do |_args|
          begin
            TSC::Error.ignore {
              @params.listener.svn_command_started(_args)
            }
            with @launcher.launch(_args).first do |_result|
              TSC::Error.ignore {
                @params.listener.svn_command_finished(_args, 0)
              }
              _result
            end
          rescue TSC::Launcher::TerminateError => error
            TSC::Error.ignore {
              @params.listener.svn_command_finished(_args, error.exited? ? error.status : -(error.signal))
            }
            raise error.errors.first
          end
        end
      end
      
      private
      #######

      def normalize_params(params)
        Hash === params ? params : Hash[ :location => params ]
      end

      def find_repository_folders(location)
        normalize_folder(location).children.select { |_entry|
          _entry.join('format').file? && _entry.join('hooks').directory?
        }
      end

      def normalize_folder(folder)
        path = Pathname.new(folder).expand_path.realpath
        path.directory? ? path : raise("Not a folder")
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'

  class Listener
    class << self
      def svn_command_started(args)
        puts ">>> STARTED: #{TSC::Launcher.normalize_command_line(args)}"
      end

      def svn_command_finished(args, status)
        puts ">>> FINISHED:#{status}: #{TSC::Launcher.normalize_command_line(args)}"
      end
    end
  end 

  depot = SK::Svn::Depot.new :location => '~svn/depots', :listener => Listener
  spo = depot.repository('spo')

  p spo.local_url
  p spo.head_revision.number
  p spo.revision(3).reload.message

  tools = depot.repository('tools')
  p tools.head_revision

  module SK
    module Svn
      class DepotTest < Test::Unit::TestCase
        def setup
        end
        
        def test_nothing
        end
      end
    end
  end
end
