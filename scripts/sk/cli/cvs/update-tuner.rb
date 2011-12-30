=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/cli/tuner.rb'

module SK
  module Cli
    module Cvs
      class UpdateTuner < SK::Cli::Tuner
        def process(io)
          io.each do |_line|
            case _line
              when %r{^cvs\s+update:\s+Updating\s+(.*?)\s*$}

              when %r{^cvs\s+update:}, %r{^cvs\s+\[update\s+aborted\]:}
                app.register_errors _line

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
    module Cli
      module Cvs
        class UpdateTunerTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
