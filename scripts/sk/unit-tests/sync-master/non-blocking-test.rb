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

        def test_nothing
        end

        if RUBY_PLATFORM == 'java'
          def test_non_blocking
            executor.in_a_thread {
              lock.synchronize(true) do
                sleep 2
              end
            }
            sleep 0.25

            assert_equal true, lock.locked?
            assert_equal false, lock.synchronize(false) { "inside" }
            sleep 2
            assert_equal "inside", lock.synchronize(false) { "inside" }
          end
        end
      end
    end
  end
end
