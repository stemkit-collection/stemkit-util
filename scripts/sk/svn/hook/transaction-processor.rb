=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'sk/svn/hook/plugin/manager.rb'
require 'sk/svn/transaction-look.rb'

module SK
  module Svn
    module Hook
      class TransactionProcessor
        attr_reader :name, :config, :repository, :manager

        def initialize(name, config, repository)
          @name = name
          @config = config
          @repository = repository

          @manager = Plugin::Manager.new(self)
        end

        def process(transaction)
          manager.invoke SK::Svn::TransactionLook.new(config.repository_path(repository), transaction)
        end

        def report_error(message, &block)
          raise 'No block given' unless block
          block.call
        end
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Svn
      module Hook
        class TransactionProcessorTest < Test::Unit::TestCase
          def setup
          end

          def teardown
          end
        end
      end
    end
  end
end
