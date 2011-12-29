=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: EMC Gennady Bystritsky
=end

module SK
  module Cli
    class Tuner
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def extra_cli_options
      end

      def check_option(option)
        option
      end

      def ready?
        true
      end

      protected
      #########

      def register_error(line)
        errors << line
      end

      def display_errors_if_any
        return if errors.empty?
        app.output_errors 'Errors or not recognized:', errors.map { |_line|
          '  > ' + _line
        }
      end

      private
      #######

      def errors
        @errors ||= []
      end

    end
  end
end
