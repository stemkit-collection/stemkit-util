=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: EMC Gennady Bystritsky
=end

ARGV.tap { |_first, *_rest|
  break unless _first == 'join-output'

  $stderr.reopen($stdout)
  Kernel.exec *_rest
}

require 'sk/scoping-launcher.rb'

module SK
  module Cli
    class TuningLauncher < SK::ScopingLauncher
      def output_info(info)
        $stdout.puts info
      end

      def output_errors(*args)
        $stderr.puts *args.flatten.compact
      end

      protected
      #########

      def command_line_arguments(args)
        [ args.map { |_item|
            check_option(_item) || tuner.check_option(_item)
          },
          Array(tuner.extra_cli_options)
        ]
      end

      def check_option(item)
        rails TSC::NotImplementedError, :check_option
      end

      def redirect_stderr_to_stdout
        @redirect = true
      end

      def launch(command, *args)
        return super(command, *args) unless tuner.ready?
        require 'open3'

        cmdline = [
          @redirect ? [ $0, 'join-output' ] : [],
          command,
          args
        ]
        Open3.popen3(*cmdline.flatten) do |_in, _out, |
          tuner.process _out
        end
      end

      def clear_tuner
        @tuner = nil
      end

      def set_tuner(tuner)
        @tuner = tuner
      end

      def tuner
        @tuner ||= NoopTuner.new
      end

      private
      #######

      class NoopTuner
        def check_option(option)
          option
        end

        def extra_cli_options
        end

        def ready?
          false
        end
      end

    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Cli
      class TuningLauncherTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
