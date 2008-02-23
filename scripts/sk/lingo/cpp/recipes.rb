=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/c/recipes.rb'

module SK
  module Lingo
    module Cpp
      module Recipes
        include SK::Lingo::C::Recipes

        def make_line_comments(lines)
          return lines if lines.empty?

          width = lines.map { |_line| _line.size }.max
          lines.map { |_line| 
            "// " +_line
          }
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
      module Cpp
        class RecipesTest < Test::Unit::TestCase
          def setup
          end
          
          def teardown
          end
        end
      end
    end
  end
end
