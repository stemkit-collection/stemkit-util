=begin
  vim: set sw=2:
  Copyright (c) 2009, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: lavandac
=end

module SK
  module Mongrel
    class Interceptor
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  module SK
    module Mongrel
      class InterceptorTest < Test::Unit::TestCase
        def setup
        end
      end
    end
  end
end
