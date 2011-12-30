=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/cli/svn/cvs-entries-status-tuner.rb'

module SK
  module Cli
    module Svn
      class CvsEntriesLogTuner < SK::Cli::Svn::CvsEntriesStatusTuner
        def check_option(option)
          return option unless [ '--no-ignore', '-I' ].include?(option)
          @noignore = true
          nil
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
        class CvsEntriesLogTunerTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
