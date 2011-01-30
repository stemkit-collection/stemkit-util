=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky <bystr@mac.com>
=end

require 'forwardable'
require 'xmlsimple'

require 'tsc/launch.rb'
require 'tsc/dataset.rb'
require 'sk/ruby.rb'
require 'xmlsimple'

module SK
  module Svn
    class Repository
      include SK::Ruby
      extend Forwardable

      DEFAULT_PARAMS = { :path => nil, :name => nil }
      def_delegators :@params, :name, :path

      def initialize(depot, params = {})
        @depot, @params = depot, TSC::Dataset.new(DEFAULT_PARAMS).update(params)
        @revisions = {}

        @launcher = TSC::Launcher.new
      end

      def local_url
        @local_url ||= "file://" + self.path.to_s
      end

      def revision(number)
        with normalize_revision_number(number) do |_number|
          @revisions[_number] || begin 
            _number.zero? ? revision_0 : revision_from_log(getlog('-r', _number).first)
          end
        end
      end

      def head_revision
        revision_from_log getlog('-r', 'HEAD').first
      end

      def tail_revision(*args)
        revision_from_log getlog(*args).last
      end

      def tail_branch_revision
        tail_revision('--stop-on-copy')
      end

      def getlog(*args)
        XmlSimple.xml_in(svn('log', '--xml', *args).join("\n")).fetch('logentry')
      end

      def svn(command, *args)
        launch 'svn', command, local_url, args
      end

      def svnlook(command, *args)
        launch 'svnlook', command, local_url, args
      end

      private
      #######

      def launch(*args)
        begin
          @launcher.launch(normalize_command_args(args)).first
        rescue TSC::Launcher::TerminateError => error
          raise error.errors.first
        end
      end
      
      def normalize_command_args(*args)
        args.flatten.compact.map { |_item|
          _item.to_s
        }
      end

      def normalize_revision_number(number)
        with number.to_s.scan(%r{^\s*(\d+)\s*$}).flatten.first do |_number|
          raise "Not a revision number - #{number.inspect}" unless _number
          _number.to_i
        end
      end

      def revision_from_log(entry)
        (@revisions[entry.fetch('revision').to_i] ||= SK::Svn::Revision.new(self, :log => entry)).update(:log => entry)
      end

      def revision_0
        require 'etc'

        @revisions[0] = SK::Svn::Revision.new self, :log => {
          "revision" => 0,
          "msg" => [ "Repository #{name.inspect} created." ],
          "author" => [ Etc.getpwuid(path.stat.uid).name ],
          "date" => [ path.stat.ctime.utc.strftime("%Y-%m-%dT%H:%M:%S.0Z") ]
        }
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'

  require 'sk/svn/depot.rb'
  require 'sk/svn/revision.rb'

  depot = SK::Svn::Depot.new
  spo = depot.repository('spo')

  p spo.local_url
  p spo.head_revision.number

  p spo.revision(3).reload.message

  module SK
    module Svn
      class RepositoryTest < Test::Unit::TestCase
        def setup
        end
        
        def test_nothing
        end
      end
    end
  end
end
