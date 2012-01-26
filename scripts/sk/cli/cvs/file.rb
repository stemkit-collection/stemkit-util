=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: EMC Gennady Bystritsky
=end

require 'pathname'

module SK
  module Cli
    module Cvs
      class File
        attr_reader :path, :status

        attr_accessor :working_revision, :repository_revision, :repository_path
        attr_accessor :commit_identifier, :sticky_tag, :sticky_date, :sticky_options

        def initialize(name, folder, status, available = true)
          @status = self.class.statuses.fetch(status, 'X <' + status.to_s + '>')
          @status = '*' if missing? and available
          @available = available
          @path = folder.join name
        end

        def to_s
          join_items "\n", description, conflicts.map { |_item|
            '  > ' + _item
          }
        end

        def description
          join_items ' ', [
            status,
            ' ' * 2,
            path,
            outdated? ? [ '...', working_revision, '->', repository_revision ] : []
          ]
        end

        def updated?
          modified? or !current? && !outdated?
        end

        def current?
          status == 'U'
        end

        def missing?
          status == '!'
        end

        def removed?
          status == 'D'
        end

        def conflict?
          status == 'C'
        end

        def unknown?
          status =~ %r{^X} ? true : false
        end

        def modified?
          [ 'M', 'G' ].include? status
        end

        def outdated?
          [ '*', 'G' ].include? status
        end

        def local_only?
          status == '?'
        end

        def added?
          status == 'A'
        end

        def add_conflict_lines(*args)
          conflicts.concat args.flatten.compact
        end

        private
        #######

        def conflicts
          @conflicts ||= []
        end

        def join_items(separator, *args)
          args.flatten.compact.join separator
        end

        class << self
          def statuses
            @statuses ||= {
              'Up-to-date' => 'U',
              'Locally Added' => 'A',
              'Locally Modified' => 'M',
              'Needs Patch' => '*',
              'Needs Merge' => 'G',
              'Needs Checkout' => '!',
              'Locally Removed' => 'D',
              'Unresolved Conflict' => 'C',
              'Entry Invalid' => '-',
              '?' => '?'
            }
          end
        end
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Cli
      module Cvs
        class FileTest < Test::Unit::TestCase
          def test_current
            Cvs::File.new('fff', Pathname.new('d1').join('d2'), 'Up-to-date').tap { |_file|
              assert_equal true, _file.current?
              assert_equal false, _file.updated?
              assert_equal false, _file.outdated?
              assert_equal 'U    d1/d2/fff', _file.to_s
            }
          end

          def test_locally_added
            Cvs::File.new('fff', Pathname.new('d1').join('d2'), 'Locally Added').tap { |_file|
              assert_equal true, _file.added?
              assert_equal true, _file.updated?
              assert_equal false, _file.outdated?
              assert_equal 'A    d1/d2/fff', _file.to_s
            }
          end

          def test_needs_patch
            Cvs::File.new('fff', Pathname.new('d1').join('d2'), 'Needs Patch').tap { |_file|
              _file.working_revision = '1.1'
              _file.repository_revision = '2.3'

              assert_equal false, _file.modified?
              assert_equal false, _file.updated?
              assert_equal true, _file.outdated?
              assert_equal '*    d1/d2/fff ... 1.1 -> 2.3', _file.to_s
            }
            Cvs::File.new('uuu', Pathname.new('d1').join('d2'), 'Needs Checkout').tap { |_file|
              _file.working_revision = '1.1'
              _file.repository_revision = '2.3'

              assert_equal false, _file.modified?
              assert_equal false, _file.updated?
              assert_equal true, _file.outdated?
              assert_equal '*    d1/d2/uuu ... 1.1 -> 2.3', _file.to_s
            }
          end

          def test_needs_merge
            Cvs::File.new('fff', Pathname.new('d1').join('d2'), 'Needs Merge').tap { |_file|
              _file.working_revision = '1.1'
              _file.repository_revision = '2.3'

              assert_equal true, _file.modified?
              assert_equal true, _file.updated?
              assert_equal true, _file.outdated?
              assert_equal 'G    d1/d2/fff ... 1.1 -> 2.3', _file.to_s
            }
          end

          def test_locally_modified
            Cvs::File.new('fff', Pathname.new('d1').join('d2'), 'Locally Modified').tap { |_file|
              assert_equal true, _file.modified?
              assert_equal true, _file.updated?
              assert_equal false, _file.outdated?
              assert_equal 'M    d1/d2/fff', _file.to_s
            }
          end

          def test_missing
            Cvs::File.new('fff', Pathname.new('d1').join('d2'), 'Needs Checkout', false).tap { |_file|
              assert_equal false, _file.modified?
              assert_equal true, _file.updated?
              assert_equal false, _file.outdated?
              assert_equal '!    d1/d2/fff', _file.to_s
            }
          end

          def test_local_only
            Cvs::File.new('aaa/bbb/fff', Pathname.new('.'), '?').tap { |_file|
              assert_equal true, _file.local_only?
              assert_equal true, _file.updated?
              assert_equal false, _file.outdated?
              assert_equal '?    aaa/bbb/fff', _file.to_s
            }
          end

          def setup
          end
        end
      end
    end
  end
end
