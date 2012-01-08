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
require 'stringio'

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
        log_method_for_name = "log_#{name}"
        unless adaptor.respond_to?(log_method_for_name)
          adaptor.log_error "#{name}: Unsupported log level: #{args.inspect} (block=#{block.inspect})"
          return false
        end

        if args.empty? == false or log_level_enabled?(name)
          make_delegating_logger(name, log_method_for_name)
          return true if send(name, *args, &block)
        end

        make_do_nothing_logger(name)
        false
      end

      private
      #######

      def log_level_enabled?(name)
        adaptor.send("#{name}?") ? true : false
      end

      def make_delegating_logger(name, log_method_for_name)
        make_singleton_method(name) { |*_args, &_block|
          output_lines_with(log_method_for_name, _args).tap { |_success|
            next unless _success
            next unless _block

            StringIO.new.tap { |_io|
              _block.call _io
              output_lines_with(log_method_for_name, _io.string) unless _io.size == 0
            }
          }
        }
      end

      def make_do_nothing_logger(name)
        make_singleton_method(name) { |*_args|
          false
        }
      end

      def adaptor
        @adaptor ||= logger
      end

      def output_lines_with(log_method_for_name, *args)
        args.flatten.each do |_item|
          _item.to_s.each do |_line|
            return false unless adaptor.send(log_method_for_name, _line.chomp)
          end
        end

        true
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
