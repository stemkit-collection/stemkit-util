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
        assert true == scope.respond_to?(:info) 
        assert true == scope.info("bbb")
        assert true == scope.info("ccc")
        assert true == scope.info

        assert_equal "INFO: abc: aaa\nINFO: abc: bbb\nINFO: abc: ccc\n", stream.string
      end

      def test_notice
        assert false == scope.notice("hello")
        assert_equal 0, stream.size
      end
      
      def test_info_block_no_message
        # Calling first time without block to test that the block passed to
        # method missing does not get implicitly used by a method definition
        # as was the case once.
        #
        scope.info

        value = false
        scope.info { |_io|
          value = true
          _io.puts "Hello"
        }
        scope.info { |_io|
          _io.puts "Goodbye"
        }
        assert true == value
        assert_equal "INFO: abc: Hello\nINFO: abc: Goodbye\n", stream.string
      end

      def test_info_block_with_message
        # Calling first time without block to test that the block passed to
        # method missing does not get implicitly used by a method definition
        # as was the case once.
        #
        scope.info

        value = false
        scope.info("zzzzz") { |_io|
          value = true
          _io.puts "Hello"
        }
        assert true == value
        assert_equal "INFO: abc: zzzzz\nINFO: abc: Hello\n", stream.string
      end

      def test_notice_block
        value = false
        scope.notice("uuu") {
          value = true
          _io.puts "Hehe"
        }
        assert false == value
        assert_equal 0, stream.size
      end

      def setup
        @scope = SK::Rt::Scope.new "abc"
        @stream = StringIO.new

        SK::Rt::Scope.controller.destination = stream
      end
    end
  end
end
