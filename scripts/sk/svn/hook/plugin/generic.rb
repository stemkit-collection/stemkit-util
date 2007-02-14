# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

module SK
  module Svn
    module Hook
      module Plugin
        class Generic
        end
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
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
