=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'sk/svn/look.rb'

module SK
  module Svn
    class TransactionLook < Look
      attr_reader :transaction

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

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  
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
