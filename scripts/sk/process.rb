# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

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

          setsid

          fork do
            block.call
            exit!
          end

          exit!
        end
        waitpid pid
      end
    end
  end
end

if $0 == __FILE__
  SK::Process.demonize(false) do
    10.times do 
      puts "Hello from #{Process.pid}"
      sleep 3
    end
  end

  puts 'Press <Enter> to exit'
  gets
end
