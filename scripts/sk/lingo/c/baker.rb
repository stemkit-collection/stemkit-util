=begin
  vim: set sw=2:
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/cpp/baker.rb'

module SK
  module Lingo
    module C
      class Baker < SK::Lingo::Cpp::Baker
        def tag
          "c"
        end
        
        def accept_by_extension(item)
          case item.extension
            when 'h'
              proc {
                header item, :header
              }

            when 'c'
              proc {
                body item, :body
              }
          end
        end

        def accept_default(item)
          proc {
            header item, :header, 'h'
            body item, :body, 'c'
          }
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
