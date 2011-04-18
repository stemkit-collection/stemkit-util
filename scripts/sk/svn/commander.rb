# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/launch.rb'
require 'sk/svn/logger.rb'

module SK
  module Svn
    class Commander
      include SK::Svn::Logger

      attr_reader :launcher

      def initialize
        @launcher = TSC::Launcher.new
      end

      def info(path, revision)
        svn 'info', path, ([ '-r', revision ] if revision)
      end

      def export(path, revision, target, *args)
        svn 'export', '-r', revision, path, target, *args
      end

      def svn(*args)
        launch 'svn', *args
      end

      def launch(*args)
        log args
        launcher.launch(args.flatten.compact).first
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  
  module SK
    module Svn
      class CommanderTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
