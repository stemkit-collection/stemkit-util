=begin
  vim: sw=2:
  Copyright (c) 2012, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: EMC Gennady Bystritsky
=end

module SK
  module Cli
    module Svn
      class CvsDiffHeaderMaker
        def initialize(app, item)
          @app, @item = app, item
        end

        def process(line)
          case line
            when %r{^[=]+$}
              produce('=' * 67)

            when %r{^(.*?)\s+(.+?)\s+[(]\s*(.+?)\s*[)]\s*$}
              case $1
                when '---'
                  @start_revision = figure_revision($3)

                when '+++'
                  @end_revision = figure_revision($3)

                else
                  report_unknown_line line
              end

              ensure_item $2

            when %r{^@@\s+[-].+?\s+[+](.+?)\s*@@$}
              @deleted = true if $1 == '0,0'

            else
              report_unknown_line
          end

        end

        def finish
          produce "RCS file: #{@item}"
          produce "retrieving revision #{cvs_revision(start_revision)}" if start_revision > 0
          produce 'diff', cvs_diff_options, File.basename(@item)
          produce '---', make_revision_string(start_revision, true)
          produce '+++', make_revision_string(end_revision, @deleted)
        end

        private
        #######

        def produce(*args)
          @app.output_info args.flatten.compact.join(' ')
        end

        def make_revision_string(revision, zero_out)
          [ (revision.zero? && zero_out ? '/dev/null' : @item),
            '1 Jan 1970 00:00:00 -0000',
            (cvs_revision(revision) unless revision.zero?)
          ]
        end

        def cvs_diff_options
          added_or_deleted? ? '-N' : [ '-u', "-r#{cvs_revision(start_revision)}" ]
        end

        def cvs_revision(revision)
          "0.#{revision}"
        end

        def added_or_deleted?
          start_revision == 0 or @deleted
        end

        def end_revision
          @end_revision or raise "End revision not encountered"
        end

        def start_revision
          @start_revision or raise "Start revision not encountered"
        end

        def report_unknown_line(line)
          raise "Unrecognized line: #{line.inspect}"
        end

        def ensure_item(item)
          raise "Unexpected item: got #{item.inspect}, need #{@item.inspect}" unless item == @item
        end

        def figure_revision(input)
          return 0 if input == 'working copy'
          return $1.to_i if input =~ %r{^revision\s+(\d+)\s*$}

          raise "Unknown revision specificaiton #{input.inspect}"
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
      module Svn
        class CvsDiffHeaderMakerTest < Test::Unit::TestCase
          def setup
          end
        end
      end
    end
  end
end
