=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

module SK
  module Svn
    class TransactionLook
      def initialize(repository, transaction)
        super repository
        @transaction = transaction
      end

      protected
      #########

      def svnlook_item_arguments
        [ '-t', transaction ]
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    module Svn
      class TransactionLookTest < Test::Unit::TestCase
        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
