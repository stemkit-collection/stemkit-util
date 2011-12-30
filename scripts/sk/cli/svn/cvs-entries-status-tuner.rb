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
    module Svn
      class CvsEntriesStatusTuner < SK::Cli::Tuner
        def check_option(option)
          @noignore = true if option == '--no-ignore'
          option
        end

        def process(io)
          io.each do |_line|
            app.output_info _line unless !@noignore and _line =~ %r{\bCVS(/\w+?([.]\w+?)?)?\s*$}
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
      module Svn
        class CvsEntriesStatusTunerTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
