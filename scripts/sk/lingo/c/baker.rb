=begin
  vim: set sw=2:
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/baker.rb'
require 'sk/lingo/c/recipes.rb'

module SK
  module Lingo
    module C
      class Baker < SK::Lingo::Baker
        include Recipes

        def initialize(*args)
          super :c, *args
        end

        def accept(item)
          case item.extension
            when 'h'
              proc {
                header item
              }

            when 'c'
              proc {
                body item
              }

            else
              if item.extension.nil? or enforced?
                proc {
                  header item, 'h'
                  body item, 'c'
                }
              end
          end
        end

        def body(item, extension = nil)
          save item, make_content(item)
        end

        def header(item, extension = nil)
          save item, make_content(item)
        end

        def inline_config_locator
          SK::Config::InlineLocator[ read_after_end_marker(__FILE__), super ]
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
        class BakerTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end

__END__

c:
  main:
    body:
      indent: 0
      content: |-
        #include <stdio.h>
        
        int main(int argc, const char* argv[])
        {
          return 0;
        }

    header:
