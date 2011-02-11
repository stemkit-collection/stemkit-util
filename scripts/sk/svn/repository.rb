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

require 'tsc/dataset.rb'
require 'sk/svn/revision.rb'

module SK
  module Svn
    class Repository
      extend Forwardable

      DEFAULT_PARAMS = { :path => nil, :name => nil }
      def_delegators :@params, :name, :path

      def initialize(depot, params = {})
        @depot, @params = depot, TSC::Dataset.new(DEFAULT_PARAMS).update(params)
        @revisions = {}
      end

      def local_url
        @local_url ||= "file://" + path.to_s
      end

      def revision(number)
        normalize_revision_number(number).tap { |_number|
          return @revisions[_number] || begin 
            _number.zero? ? revision_0 : revision_from_log(getlog('-r', _number).first)
          end
        }
      end

      def head_revision
        getlog('-r', 'HEAD').tap { |_entries|
          return _entries.empty? ? revision(0) : revision_from_log(_entries.first)
        }
      end

      def tail_revision(*args)
        revision_from_log getlog('-r', '0:HEAD', '--limit', '2', *args).first
      end

      def tail_branch_revision
        tail_revision('--stop-on-copy')
      end

      def getlog(*args)
        XmlSimple.xml_in(svn('log', '--xml', *args).join("\n")).fetch('logentry', [])
      end

      def svn(command, *args)
        launch 'svn', command, local_url, args
      end

      def svnlook(command, *args)
        launch 'svnlook', command, path.to_s, args
      end

      def svnadmin(command, *args)
        launch 'svnadmin', command, path.to_s, args
      end

      private
      #######

      def launch(*args)
        @depot.launch(*args)
      end

      def normalize_revision_number(number)
        number.to_s.scan(%r{^\s*(\d+)\s*$}).flatten.first.tap { |_number|
          return _number.to_i if _number
          raise "Not a revision number - #{number.inspect}"
        }
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
