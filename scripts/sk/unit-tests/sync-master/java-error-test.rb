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
        if RUBY_PLATFORM == 'java'
          def test_java_error
            par1 = 0
            par2 = 0
            par3 = 0
            par4 = 0
            par5 = 0
            executor.in_a_thread {
              lock.synchronize(true) do
                $stderr.puts "Thread 1 - in"
                par1 = 1
                sleep 4
                $stderr.puts "Thread 1 - out"
              end
            }
            executor.in_a_thread {
              lock.synchronize(true) do
                $stderr.puts "Thread 2 - in"
                par2 = 2
                sleep 2
                java.util.ArrayList.new.get(0)
                $stderr.puts "Thread 2 - out"
              end
            }
            executor.in_a_thread {
              lock.synchronize(false) do
                $stderr.puts "Thread 3 - in"
                par3 = 3
                sleep 4
                $stderr.puts "Thread 3 - out"
              end
            }
            executor.in_a_thread {
              lock.synchronize(true) do
                $stderr.puts "Thread 4 - in"
                par4 = 4
                sleep 2
                java.util.ArrayList.new.get(0)
                $stderr.puts "Thread 4 - out"
              end
            }
            executor.in_a_thread {
              lock.synchronize(true) do
                $stderr.puts "Thread 5 - in"
                par5 = 5
                sleep 2
                $stderr.puts "Thread 5 - out"
              end
            }
            sleep 0.25

            assert_equal "inside", lock.synchronize(true) { "inside" }
            assert_equal false, lock.locked?
            $stderr.puts "Past threads"
            assert_equal 1, par1
            assert_equal 2, par2
            assert_equal 0, par3
            assert_equal 4, par4
            assert_equal 5, par5
            $stderr.puts Time.now
            sleep 3
            assert_equal false, lock.locked?
            $stderr.puts "End of test"
          end
        end
      end
    end
  end
end
