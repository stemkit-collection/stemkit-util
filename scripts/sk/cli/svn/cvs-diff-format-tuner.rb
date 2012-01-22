=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/cli/tuner.rb'
require 'sk/cli/svn/cvs-diff-header-maker.rb'

module SK
  module Cli
    module Svn
      class CvsDiffFormatTuner < SK::Cli::Tuner
        def check_option(option)
          return option unless [ '--no-ignore', '-I' ].include?(option)
          @noignore = true
          nil
        end

        def process(io)
          io.each do |_line|
            unless @noignore
              @noshow = ($2 ? true : false) if _line =~ %r{^Index:\s+(.*?)(\bCVS(?:/\w+?(?:[.]\w+?)?)?)?\s*$}
            end

            next if @noshow

            case _line
              when %r{^Index:\s*(.*?)\s*$}
                collector.start($1)

              when %r{^@@}
                collector.process(_line)
                collector.finish

              else
                next if collector.process(_line)

            end
            app.output_info _line
          end

          collector.finish
        end

        private
        #######

        class Collector
          def initialize(app)
            @app = app
          end

          def start(item)
            finish
            @processor = Svn::CvsDiffHeaderMaker.new(@app, item)
          end

          def finish
            return unless @processor
            @processor.finish
            @processor = nil
          end

          def process(line)
            return false unless @processor
            @processor.process(line)
            true
          end
        end

        def collector
          @collector ||= Collector.new(app)
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
        class CvsEntriesDiffTunerTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
