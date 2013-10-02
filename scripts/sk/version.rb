=begin
  vim: sw=2:
  Copyright (c) 2013, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Bystritsky, Gennady (bystr@mac.com)
=end

module SK
  class Version
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    class VersionTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
    end
  end
end
