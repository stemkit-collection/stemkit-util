=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/cvs/cli/tuner.rb'

module SK
  module Cvs
    module Cli
      class DiffTuner < SK::Cvs::Cli::Tuner
        def extra_cvs_options
          [ '-u', '-N' ]
        end

        def process(io)
          io.each do |_line|
            case _line
              when %r{^cvs\s+diff:\s+Diffing\s+(.*?)\s*$}

              when %r{^[?]\s+(.*)$}

              else
                app.output_info _line
            end
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
    module Cvs
      module Cli
        class DiffTunerTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
