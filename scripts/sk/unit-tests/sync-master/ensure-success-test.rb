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
  require 'sk/tests/sync-master/sync-master-fixture.rb'

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

        def test_ensure_succeeds_immediatelly
          block_called = false
          assert_nothing_raised do
            lock.synchronize do |_condition|
              _condition.ensure depot.empty? do
                block_called = true
              end
            end
            assert_equal false, block_called
          end
        end
      end
    end
  end
end
