=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

module SK
  module Lingo
    module C
      module Recipes
        def make_h_guard(*args)
          tag = "_#{args.flatten.compact.join('_').upcase}_"
          [
            "#ifndef #{tag}",
            "#define #{tag}",
            yield,
            "#endif /* #{tag} */"
          ]
        end

        def make_cpp_guard
          [
            '#if defined(__cplusplus)',
            'extern "C" {',
            '#endif',
            yield,
            '#if defined(__cplusplus)',
            '}',
            '#endif'
          ]
        end

        def make_block_comments(lines)
          return lines if lines.empty?

          first, *rest = lines
          [ "/*  #{first}" ] + rest.map { |_line| " *  #{_line}" } + [ '*/' ]
        end

        def make_line_comments(lines)
          return lines if lines.empty?

          width = lines.map { |_line| _line.size }.max
          lines.map { |_line| 
            "/* %-#{width}.#{width}s */" % _line
          }
        end

        def make_comments(lines)
          lines.size == 1 ? make_line_comments(lines) : make_block_comments(lines)
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
      module C
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
