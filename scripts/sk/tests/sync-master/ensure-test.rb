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
        def test_ensure
          executor.in_a_thread do
            loop do
              5.times do
                lock.synchronize do |_condition|
                  depot.push 0
                  _condition.announce
                end
                sleep 0.1
              end
              sleep 0.5
            end
          end

          registry = []
          lock.synchronize do |_condition|
            _condition.ensure depot.size >= 5, 1 do
              registry.push depot.size
            end
            assert_equal 5, depot.size
            assert_equal true, lock.owner?
            sleep 1
            assert_equal 5, depot.size
          end

          assert_equal [ 1, 2, 3, 4 ], registry
        end
      end
    end
  end
end
