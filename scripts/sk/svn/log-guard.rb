=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'sk/svn/hook/plugin/generic.rb'
require 'tsc/border-box.rb'

module SK
  module Svn
    class LogGuard < Hook::Plugin::Generic
      def process(info)
        guard = config.repositories[info.depot]['log-guard'] or return

        return unless guard['enforce'] == true
        return unless info.log.to_s.strip.empty?

        message = guard['message']
        $stderr.puts TSC::BorderBox[ message ] if message

        raise 'Empty log message'
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Svn
      class AccessModeratorTest < Test::Unit::TestCase
        def setup
        end

        def teardown
        end
      end
    end
  end
end
