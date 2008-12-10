# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
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
        def test_populate_with_lock_must_succeed
          assert make_slices(10, 1000, 500).all? { |_item|
            _item == 1
          }
        end

        # This test is known to create havoc - not a legitimate scenario
        def NO_test_populate_no_lock_must_fail
          lock.expects(:synchronize).at_least_once.yields
          assert make_slices(2, 10, 5).any? { |_item|
            _item != 1
          }
        end
      end
    end
  end
end
