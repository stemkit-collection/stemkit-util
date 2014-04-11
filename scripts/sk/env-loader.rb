=begin
  vim: sw=2:
  Copyright (c) 2014 Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Bystritsky, Gennady
=end

module SK
  module EnvLoader
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    class EnvLoaderTest < Test::Unit::TestCase
      def setup
      end
    end
  end
end
