=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: EMC Gennady Bystritsky
=end

require 'sk/cli/tuner.rb'
require 'sk/cli/cvs/file.rb'

module SK
  module Cli
    module Cvs
      class StatusTuner < SK::Cli::Tuner
        def check_option(option)
          case option
            when '-u'
              @updates = true

            else
              return super
          end

          nil
        end

        def process(io)
          io.each do |_line|
            case _line
              when %r{^cvs\s+status:\s+Examining\s+(.*?)\s*$}
                set_folder $1

              when %r{^File:\s+(.*?)\s+Status:\s+(.*?)\s*$}
                set_file $1, $2

              when %r{^[?]\s+(.*)$}
                item = $1
                next if item.split('/').any? { |_item|
                  _item == '.svn'
                }
                set_folder '.'
                set_file item, '?'

              when %r{^[= ]*$}

              when %r{^\s*Working revision:\s*(.*?)\s*$}
                file.working_revision = $1

              when %r{^\s*Commit Identifier:\s*(.*?)\s*$}
                file.commit_identifier = $1

              when %r{^\s*Sticky Tag:\s*(.*?)\s*$}
                file.sticky_tag = $1

              when %r{^\s*Sticky Date:\s*(.*?)\s*$}
                file.sticky_date = $1

              when %r{^\s*Sticky Options:\s*(.*?)\s*$}
                file.sticky_options = $1

              when %r{^\s*Repository revision:\s*(.*?)\s+(.*?)\s*$}
                file.repository_revision = $1
                file.repository_path = $2

              else
                app.register_errors _line
            end
          end

          dump_file
        end

        private
        #######

        def set_folder(folder)
          @folder = Pathname.new(folder)
        end

        def folder
          @folder or raise 'No folder information encountered'
        end

        def file
          @file or raise 'No file information encountered'
        end

        def set_file(name, status)
          dump_file
          @file = File.new name, folder, status
        end

        def dump_file
          return unless @file

          app.output_info @file.to_s if @file.updated? or (@file.outdated? and @updates)

          @file = nil
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
        class StatusTunerTest < Test::Unit::TestCase
          attr_reader :tuner, :errors, :infos

          def test_output_without_updates
            tuner.process [
              '? aaa/bbb/ccc',
              'File: aaa.c Status: Locally Modified',
              'cvs status: Examining d1/d2/d3',
              'File: zzz.rb Status: Up-to-date',
              '   Working revision: 1.4',
              'some line',
              '   Repository revision: 7.5 /home/a/b/c/uuu.rb',
              'File: bbb.rb Status: Needs Patch',
              '   Working revision: 1.4',
              '   Repository revision: 7.5 /home/a/b/c/uuu.rb',
              'File: uuu.rb Status: Needs Merge',
              '   Working revision: 1.4',
              '   Repository revision: 7.5 /home/a/b/c/uuu.rb',
              'zzzzzzzzzzzzzzzz'
            ]

            assert_equal 3, infos.size
            assert_equal '?    aaa/bbb/ccc', infos[0]
            assert_equal 'M    aaa.c', infos[1]
            assert_equal 'G    d1/d2/d3/uuu.rb ... 1.4 -> 7.5', infos[2]


            assert_equal 2, errors.size
            assert_equal 'some line', errors[0]
            assert_equal 'zzzzzzzzzzzzzzzz', errors[1]
          end

          def test_output_with_updates
            tuner.check_option('-u')
            tuner.process [
              '? aaa/bbb/ccc',
              'File: aaa.c Status: Locally Modified',
              'cvs status: Examining d1/d2/d3',
              'File: zzz.rb Status: Up-to-date',
              '   Working revision: 1.4',
              '   Repository revision: 7.5 /home/a/b/c/uuu.rb',
              'File: bbb.rb Status: Needs Patch',
              '   Working revision: 1.4',
              '   Repository revision: 7.5 /home/a/b/c/uuu.rb',
              'File: uuu.rb Status: Needs Merge',
              '   Working revision: 1.4',
              '   Repository revision: 7.5 /home/a/b/c/uuu.rb',
              'zzzzzzzzzzzzzzzz'
            ]

            assert_equal 4, infos.size
            assert_equal '?    aaa/bbb/ccc', infos[0]
            assert_equal 'M    aaa.c', infos[1]
            assert_equal '*    d1/d2/d3/bbb.rb ... 1.4 -> 7.5', infos[2]
            assert_equal 'G    d1/d2/d3/uuu.rb ... 1.4 -> 7.5', infos[3]


            assert_equal 1, errors.size
            assert_equal 'zzzzzzzzzzzzzzzz', errors[0]
          end

          def output_info(info)
            infos << info
          end

          def register_errors(*args)
            errors.concat args.flatten.compact
          end

          def setup
            @errors = []
            @infos = []

            @tuner = SK::Cli::Cvs::StatusTuner.new(self)
          end
        end
      end
    end
  end
end
