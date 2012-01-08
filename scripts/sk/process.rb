# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
#
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/errors.rb'
require 'timeout'

module SK
  class Process
    class << self
      include ::Process

      def demonize(blind = true, &block)
        raise 'No block specified' unless block

        pid = fork do
          File.open('/dev/null', 'w+') do |_io|
            $stdin.reopen _io

            if blind
              $stdout.reopen _io
              $stderr.reopen _io
            end
          end

          cleanup_file_descriptors 3...256
          setsid

          fork do
            block.call
            exit!
          end

          exit!
        end
        waitpid pid
      end

      alias_method :daemonize, :demonize

      def cleanup_file_descriptors(descriptors)
        descriptors.each do |_descriptor|
          TSC::Error.ignore {
            IO.open(_descriptor).close
          }
        end
      end

      def stop(pid, tolerance = 3)
        kill 'INT', pid rescue return
        begin
          timeout tolerance do
            loop do
              kill 0, pid rescue break
              sleep 1
            end
          end
        rescue Timeout::Error
          kill 'KILL', pid
        end
      end
    end
  end
end

