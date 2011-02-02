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

module SK
  module Svn
    class Depot
      attr_reader :repositories

      DEFAULT_PARAMS = { :location => "~/depots" }

      def initialize(params = {})
        @params = TSC::Dataset.new(DEFAULT_PARAMS).update(normalize_params(params))

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
        begin
          @launcher.launch(normalize_command_args(args)).first
        rescue TSC::Launcher::TerminateError => error
          raise error.errors.first
        end
      end
      
      private
      #######

      def normalize_params(params)
        Hash === params ? params : Hash[ :location => params ]
      end

      def normalize_command_args(*args)
        args.flatten.compact.map { |_item|
          _item.to_s
        }
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

  depot = SK::Svn::Depot.new
  spo = depot.repository('spo')

  p spo.local_url
  p spo.head_revision.number

  m = spo.revision(3).reload.message
  p spo.revision(3).reload.message

  spo.revision(3).reload.message = m * 2
  p spo.revision(3).reload.message

  spo.revision(3).reload.message = m 
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
