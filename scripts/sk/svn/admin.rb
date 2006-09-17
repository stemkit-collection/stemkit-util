# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

module SK
  module Svn
    class Admin
      attr_reader :repository, :revision
      def initialize(repository, revision)
        @repository = repository
        @revision = revision
      end

      def dump(file)
        launch "svnadmin dump -r #{revision} --incremental --deltas -q #{repository} > #{file}"
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  module Sk
    module Svn
      class AdminTest < Test::Unit::TestCase
        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
