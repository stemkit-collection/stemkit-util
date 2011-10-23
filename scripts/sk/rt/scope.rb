=begin
  vim: sw=2:
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

# This separation is designed for substituting pure ruby implementation with
# the C++ one from stemkit-cpp runtime library.
# 
require 'sk/rt/scope-implementation.rb' unless defined? SK::Rt::Scope

module SK
  module Rt
    class Scope
      private :logger

      def fatal(*args, &block)
        error(*args, &block)
      end

      def warn(*args, &block)
        warning(*args, &block)
      end

      def method_missing(name, *args, &block)
        log_name = "log_#{name}"
        unless adaptor.respond_to?(log_name)
          adaptor.log_error "#{name}: Unsupported log level: #{args.inspect} (block=#{block.inspect})"
          return false
        end

        make_singleton_method(name) { |*_args|
          catch :break do
            foreach_line_in _args do |_line|
              adaptor.send(log_name, _line) or throw :break, false
            end

            true
          end
        }
        send(name, *args, &block).tap { |_success|
          next unless _success
          make_singleton_method(name) { |*_args| 
            false 
          }
        }
      end

      private
      #######

      def adaptor
        @adaptor ||= logger
      end

      def foreach_line_in(*args)
        args.flatten.each do |_item|
          _item.to_s.each do |_line|
            yield _line.chomp
          end
        end
      end

      def singleton_class
        class << self
          self
        end
      end

      def make_singleton_method(*args, &block)
        singleton_class.send :define_method, *args, &block
      end
    end
  end
end
