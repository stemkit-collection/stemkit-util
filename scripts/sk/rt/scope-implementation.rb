=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky <bystr@mac.com>
=end

require 'sk/rt/controller.rb'

module SK
  module Rt
    class Scope
      attr_reader :logger, :name

      def initialize(name)
        @name = name
        @logger = Logger.new self
      end

      class << self
        def controller
          @controller ||= SK::Rt::Controller.new
        end
      end

      private
      #######
      
      class Logger
        def initialize(scope)
          @scope_name = scope.name
          @controller = scope.class.controller
        end

        class << self
          def define_log_methods(*args)
            args.each do |_name|
              define_method("log_#{_name}") { |_message|
                @controller.output _name, @scope_name, _message
              }
              define_method("#{_name}?") {
                @controller.enabled? _name, @scope_name
              }
            end
          end
        end

        define_log_methods :error, :stat, :warning, :info, :notice, :detail, :debug
      end
    end
  end
end
