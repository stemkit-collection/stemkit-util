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

module SK
  module Svn
    class Depot
      attr_reader :repositories

      def initialize(location = "~/depots")
        @repositories = find_repository_folders(location).map { |_folder|
          Repository.new self, :name => _folder.basename.to_s, :path => _folder
        }
      end

      def repository(name)
        @repositories.detect { |_repo|
          _repo.name == name
        }
      end

      private
      #######

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
