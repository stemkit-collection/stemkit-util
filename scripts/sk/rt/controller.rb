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

      def output(*args)
        destination.puts *args
      end

      private
      #######

      attr_reader :destination
    end
  end
end

