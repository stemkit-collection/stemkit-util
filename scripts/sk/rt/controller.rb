=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky <bystr@mac.com>
=end

module SK
  module Rt
    class Controller
      def initialize
        @destination = $stderr
        @levels = [ :error, :stat, :warning, :info, :notice, :detail, :debug ]
        @scope_to_level = Hash.new :info
      end

      def set_scope_level(scope, level)
        raise "Unsupported log level" unless @levels.include? level
        @scope_to_level[scope.to_s] = level
      end

      def destination=(io)
        @destination = io
      end

      def enabled?(level, scope)
        first, second = [ level, @scope_to_level[scope] ].map { |_item|
          @levels.index(_item) or -1
        }
        first <= second
      end

      def output(level, scope, message)
        enabled?(level, scope).tap { |_enabled|
          _enabled and @destination.puts "#{level.to_s.upcase}: #{scope}: #{message}"
        }
      end

      private
      #######

    end
  end
end

