=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: EMC Gennady Bystritsky
=end

module SK
  module Cvs
    module Cli
      class StatusTuner
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
          def setup
          end
        end
      end
    end
  end
end
