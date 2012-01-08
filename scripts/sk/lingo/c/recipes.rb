=begin
  vim: set sw=2:
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/lingo/cpp/recipes.rb'

module SK
  module Lingo
    module C
      module Recipes
        include SK::Lingo::Cpp::Recipes

        def make_line_comments(*args)
          lines = args.flatten.compact
          return lines if lines.empty?

          width = lines.map { |_line| _line.size }.max
          lines.map { |_line|
            "/* %-#{width}.#{width}s */" % _line
          }
        end
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Lingo
      module C
        class RecipesTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
