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

module SK
  module Svn
    class Depot
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
        } or raise "Repository #{name.inspect} not available"
      end

      def launch(*args)
        TSC::Launcher.normalize_command_args(args).tap { |_args|
          begin
            @params.listener.svn_command_started(_args)
            @launcher.launch(_args).first.tap { |_result|
              @params.listener.svn_command_finished(_args, 0)
              return _result
            }
          rescue TSC::Launcher::TerminateError => error
            @params.listener.svn_command_finished(_args, error.exited? ? error.status : -(error.signal))
            raise error.errors.first
          end
        }
      end
      
      def svn_command_started(args)
      end

      def svn_command_finished(args, status)
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

  depot = SK::Svn::Depot.new :location => '~/depots' #, :listener => Listener
  spo = depot.repository('stemkit')

  p spo.local_url
  p spo.head_revision.number
  p spo.revision(3).reload.message

  tools = depot.repository('tsc-tpm')
  p tools.head_revision.number

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
