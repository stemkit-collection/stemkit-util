=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'etc'

module SK
  module Lingo
    class Config
      attr_reader :options, :hash

      def initialize(options, hash)
        @options = options
        @hash = hash
      end

      def indent
        @indent ||= (options.indent || hash['indent']).to_i
      end

      def copyright_holders
        holders = Array(hash['copyright_holders'])
        holders.push user.gecos if holders.empty?

        lines holders
      end

      def authors
        authors = Array(hash['authors'])
        authors.push user.gecos if authors.empty?

        lines authors
      end

      def license
        lines hash['license']
      end

      def lines(content)
        unit = nil
        content.to_s.map { |_line| 
          # Here the line gets re-indented to the value specified 
          # either in the config file or on the command line (-i).
          #
          spaces, line = _line.chomp.scan(%r{^(\s*)(.*)$}).first
          offset = spaces.count(" ") + spaces.count("\t") * 8
          unit ||= (offset unless offset.zero?)

          (unit ? ' ' * ((offset/unit)*indent) : '') + line
        }
      end

      def user
        @user ||= Etc.getpwuid
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    module Lingo
      class ConfigTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
