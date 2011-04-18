=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

module SK
  module Lingo
    module Recipe
      module Comments
        def make_pound_comments(*args)
          args.flatten.compact.map { |_line|
            '# ' + _line
          }
        end
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  module SK
    module Lingo
      module Recipe
        class CommentsTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
