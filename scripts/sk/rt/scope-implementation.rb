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
          @scope = scope
        end

        class << self
          def define_log_methods(*args)
            args.each do |_name|
              define_method "log_#{_name}" do |_message|
                log _name, _message
              end

              define_method "#{_name}?" do 
                enabled? _name
              end
            end
          end
        end

        define_log_methods :error, :stat, :warning, :info, :notice, :detail, :debug

        private
        #######

        attr_reader :scope

        def enabled?(level)
          [ :error, :stat, :warning, :info ].include? level
        end
        
        def log(level, message)
          enabled?(level).tap { |_enabled|
            scope.class.controller.output "#{level.to_s.upcase}: #{scope.name}: #{message}" if _enabled
          }
        end
      end
    end
  end
end
