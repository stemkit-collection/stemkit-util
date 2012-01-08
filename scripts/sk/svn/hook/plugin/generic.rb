# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
#
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/errors.rb'

module SK
  module Svn
    module Hook
      module Plugin
        class Generic
          attr_reader :config

          def initialize(config)
            @config = config
          end

          def process(info)
            raise TSC::NotImplementedError, :process
          end
        end
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'

  module SK
    module Svn
      module Hook
        module Plugin
          class GenericTest < Test::Unit::TestCase
            def setup
            end

            def teardown
            end
          end
        end
      end
    end
  end
end
