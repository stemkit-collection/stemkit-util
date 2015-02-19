# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

if $0 == __FILE__
  require 'sk/sync-master.rb'
  require './sync-master-fixture.rb'

  module SK
    module Tests
      class SyncMasterTest < Test::Unit::TestCase
        include SK::Tests::SyncMasterTester

        def lock
          @lock ||= SyncMaster.new
        end

        def setup
          super
        end

        def test_ensure_timeout
          block_called = false
          assert_raises SyncMaster::TimeoutError do
            lock.synchronize do |_condition|
              _condition.ensure depot.size > 0, 1 do
                block_called = true
              end
            end
            assert_equal true, block_called
          end
        end
      end
    end
  end
end
