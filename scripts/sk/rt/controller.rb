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
      end

      def destination=(io)
        @destination = io
      end

      def enabled?(level, scope)
        [ :error, :stat, :warning, :info ].include? level
      end

      def output(level, scope, message)
        enabled?(level, scope).tap { |_enabled|
          destination.puts "#{level.to_s.upcase}: #{scope}: #{message}" if _enabled
        }
      end

      private
      #######

      attr_reader :destination
    end
  end
end

