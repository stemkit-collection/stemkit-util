=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: EMC Gennady Bystritsky
=end

require 'sk/cvs/cli/tuner.rb'
require 'sk/cvs/cli/file.rb'

module SK
  module Cvs
    module Cli
      class StatusTuner < SK::Cvs::Cli::Tuner
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
                set_folder '.'
                set_file $1, '?'

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
                errors << _line
            end
          end

          dump_file
          display_errors_if_any
        end

        private
        #######

        def errors
          @errors ||= []
        end

        def display_errors_if_any
          return if errors.empty?
          app.output_errors 'Errors or not recognized:', errors.map { |_line|
            '  > ' + _line
          }
        end

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
    module Cvs
      module Cli
        class StatusTunerTest < Test::Unit::TestCase
          attr_reader :tuner, :error_depot, :info_depot

          def test_overall
            tuner.process [
              '? aaa/bbb/ccc',
              'File: aaa.c Status: Locally Modified',
              'cvs status: Examining d1/d2/d3',
              'File: uuu.rb Status: Needs Merge',
              '   Working revision: 1.4',
              '   Repository revision: 7.5 /home/a/b/c/uuu.rb',
              'zzzzzzzzzzzzzzzz'
            ]

            assert_equal 3, info_depot.size
            assert_equal '?    aaa/bbb/ccc', info_depot[0]
            assert_equal 'M    aaa.c', info_depot[1]
            assert_equal 'G    d1/d2/d3/uuu.rb ... 1.4 -> 7.5', info_depot[2]


            assert_equal 2, error_depot.size
            assert_equal 'Errors or not recognized:', error_depot[0]
            assert_equal '  > zzzzzzzzzzzzzzzz', error_depot[1]
          end

          def output_info(info)
            info_depot << info
          end

          def output_errors(*args)
            error_depot.concat args.flatten.compact
          end

          def setup
            @error_depot = []
            @info_depot = []

            @tuner = SK::Cvs::Cli::StatusTuner.new(self)
          end
        end
      end
    end
  end
end
