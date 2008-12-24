=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'etc'
require 'pp'
require 'sk/lingo/ingredients.rb'

module SK
  module Lingo
    class Config
      include Ingredients

      attr_reader :options, :data, :tag, :target

      def initialize(tag, options, data)
        @options = options
        @data = data

        @tag = tag ? @data.fetch(tag, data.class.new) : @data

        if options.mode?
          @target = @tag.fetch(options.mode, data.class.new)
        else
          @target = @tag.fetch(:default, @tag)
        end

        10.times do
          return unless @target.key?(:like)
          @target = @tag.fetch @target.fetch(:like), data.class.new
        end

        raise "Looping in resolving like-ness"
      end

      def indent
        @indent ||= (options.indent || data['indent']).to_i
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
