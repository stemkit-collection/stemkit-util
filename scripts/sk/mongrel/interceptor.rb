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
      ENVIRONMENT_MARKER = 'sk.mongrel.interceptor'
      class << self
        def intercept_unless_already(top)
          return unless defined? ::Mongrel::Command::Base
          return if ENV[ENVIRONMENT_MARKER] == "active"

          ObjectSpace.each_object(::Mongrel::Command::Base) do |_object|
            if _object.class.name.split("::").last == "Start"
              ENV[ENVIRONMENT_MARKER] = "active"
              self.new(top).start(_object.original_args)
            end
          end
        end
      end

      def initialize(top)
        @top = top
      end

      def start(*args)
        close_mongrel_listeners
        exec command, 'start', *args.flatten
      end

      private
      #######

      def command
        File.join(@top, 'script', 'mongrel_interceptor')
      end

      def close_mongrel_listeners
        ObjectSpace.each_object(::TCPSocket) do |_object|
          _object.close
        end
      end
    end
  end
end

if $0 == __FILE__ 
  begin
    require 'test/unit'
    require 'mocha'

    module SK
      module Mongrel
        class InterceptorTest < Test::Unit::TestCase
          def setup
          end
        end
      end
    end
  rescue LoadError
  end
end
