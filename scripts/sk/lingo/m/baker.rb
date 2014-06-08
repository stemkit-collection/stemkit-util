=begin
  vim: set sw=2:
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/lingo/cpp/baker.rb'
# require 'sk/lingo/c/recipes.rb'

module SK
  module Lingo
    module M
      class Baker < SK::Lingo::Cpp::Baker
        # include SK::Lingo::M::Recipes

        def tag
          'm'
        end

        def accept_by_extension(item)
          case item.extension
            when 'h'
              proc {
                header item, :header
              }

            when 'm'
              proc {
                body item, :body
              }
          end
        end

        def accept_default(item)
          proc {
            header item, :header, 'h'
            body item, :body, 'm'
          }
        end

        def inline_config_locator
          SK::Config::InlineLocator[ read_after_end_marker(__FILE__), super ]
        end

        def make_qualified_name(*args)
          args.flatten.compact.join('_')
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
      module M
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

m:
  indent: 4
  default:
    header:
      indent: 0
      content: |-
        #import <UIKit/UIKit.h>

        @interface #{full_class_name} : NSObject
          @property (readonly, nonatomic) NSObject* property;

          - (BOOL) method: (NSObject*) parameter;
        @end

    body:
      indent: 0
      content: |-
        #import #{class_reference(:h)}

        @interface #{full_class_name} () {
            NSObject* _instanceVariable;
          }
        @end

        @implementation #{full_class_name}
          - (BOOL) method: (NSObject*) parameter {
            return YES;
          }
        @end

  main:
    body:
      indent: 0
      content: |-
        #import <UIKit/UIKit.h>
        #import "app/Delegate.h"

        int main(int argc, char* argv[])
        {
          @autoreleasepool {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
          }
        }

    header:

  ain:
    like: main

