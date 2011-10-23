=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky <bystr@mac.com>
=end

require 'test/unit'
require 'mocha'
require 'stringio'

require 'sk/rt/scope.rb'

module SK
  module Rt
    class ScopeTest < Test::Unit::TestCase
      attr_reader :scope, :stream

      def test_info
        assert false == scope.respond_to?(:info) 
        assert true == scope.info("aaa")
        # assert true == scope.respond_to?(:info) 

        assert true == scope.info("aaa")
        assert true == scope.info("aaa")
      end

      def test_notice
        assert false == scope.notice
      end

      def setup
        @scope = SK::Rt::Scope.new "abc"
        @stream = StringIO.new

        SK::Rt::Scope.controller.destination = stream
      end
    end
  end
end
