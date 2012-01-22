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
        class WrongInputError < Exception
          def initialize(line)
            super "Unrecognized input line: #{line.inspect}"
          end
        end

        class WrongItemError < Exception
          def initialize(args)
            given, needed = args
            super "Unexpected item: got #{given.inspect}, need #{needed.inspect}"
          end
        end

        class MissingRevisionError < Exception
          def initialize(label)
            super "No revision - #{label.inspect}"
          end
        end

        class WrongRevisionError < Exception
          def initialize(spec)
            super "Unknown revision specificaiton #{spec.inspect}"
          end
        end

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
              report_unknown_line line
          end

        end

        def finish
          produce "RCS file: #{@item}"
          produce "retrieving revision #{cvs_revision(start_revision)}" if start_revision > 0
          produce 'diff', cvs_diff_options, File.basename(@item)
          produce '---', make_revision_string(start_revision, true)
          produce '+++', make_revision_string(end_revision, @deleted)
        end

        def end_revision
          @end_revision or raise MissingRevisionError, :end
        end

        def start_revision
          @start_revision or raise MissingRevisionError, :start
        end

        def added_or_deleted?
          start_revision == 0 || @deleted ? true : false
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

        def report_unknown_line(line)
          raise WrongInputError, line
        end

        def ensure_item(item)
          raise WrongItemError, [ item, @item ] unless item == @item
        end

        def figure_revision(input)
          return 0 if input == 'working copy'
          return $1.to_i if input =~ %r{^revision\s+(\d+)\s*$}

          raise WrongRevisionError, input
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
          attr_reader :depot
          def test_sends_67_equals_on_any_equals_line
            CvsDiffHeaderMaker.new(self, "abc.rb").tap do |_maker|
              _maker.process("====");
              assert_equal 1, depot.size
              assert_equal 67, depot.first.size
            end
          end

          def test_fails_on_wrong_input
            CvsDiffHeaderMaker.new(self, "abc.rb").tap do |_maker|
              assert_raises CvsDiffHeaderMaker::WrongInputError do
                _maker.process("ljkjkjkjlkjlj")
              end

              assert_raises CvsDiffHeaderMaker::WrongInputError do
                _maker.process("----- abc.rb (revision 78)")
              end
            end
          end

          def test_fails_start_end_revision_with_different_name
            CvsDiffHeaderMaker.new(self, "abc.rb").tap do |_maker|
              assert_raises CvsDiffHeaderMaker::WrongItemError do
                _maker.process "--- zzz (revision 3)"
              end

              assert_raises CvsDiffHeaderMaker::WrongItemError do
                _maker.process "+++ zzz (revision 3)"
              end
            end
          end

          def test_fails_wrong_revision
            CvsDiffHeaderMaker.new(self, "abc.rb").tap do |_maker|
              assert_raises CvsDiffHeaderMaker::WrongRevisionError do
                _maker.process "--- abc.rb (rev 3a)"
              end

              assert_raises CvsDiffHeaderMaker::WrongRevisionError do
                _maker.process "+++ abc.rb (some text)"
              end
            end
          end

          def test_succeeds_on_correct_revision
            CvsDiffHeaderMaker.new(self, "abc.rb").tap do |_maker|
              assert_raises CvsDiffHeaderMaker::MissingRevisionError do
                _maker.start_revision
              end

              assert_raises CvsDiffHeaderMaker::MissingRevisionError do
                _maker.end_revision
              end

              _maker.process "--- abc.rb (revision 3)"
              _maker.process "+++ abc.rb (working copy)"

              assert_equal 3, _maker.start_revision
              assert_equal 0, _maker.end_revision
            end
          end

          def test_checks_for_added_and_deleted_files
            CvsDiffHeaderMaker.new(self, "abc.rb").tap do |_maker|
              assert_raises CvsDiffHeaderMaker::MissingRevisionError do
                _maker.added_or_deleted?
              end

              _maker.process('--- abc.rb (working copy)')
              assert_equal true, _maker.added_or_deleted?

              _maker.process('--- abc.rb (revision 34)')
              assert_equal false, _maker.added_or_deleted?

              _maker.process("@@ -34,67 +56,88 @@")
              assert_equal false, _maker.added_or_deleted?

              _maker.process("@@ -34,67 +0,0 @@")
              assert_equal true, _maker.added_or_deleted?
            end
          end

          def setup
            @depot = []
          end

          def output_info(line)
            @depot << line
          end
        end
      end
    end
  end
end
