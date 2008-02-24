=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'etc'
require 'sk/lingo/config.rb'
require 'sk/lingo/ruby/ingredients.rb'

module SK
  module Lingo
    module Ruby
      class Config < SK::Lingo::Config
        include Ingredients

        def initialize(*args)
          super :ruby, *args
        end
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    module Lingo
      module Ruby
        class ConfigTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
