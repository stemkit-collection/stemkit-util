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
    module Objc
      class Baker < SK::Lingo::Cpp::Baker
        def tag
          'objc'
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
      module Objc
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

objc:
  source-indent: 2
  indent: 4
  default:
    header:
      indent: 0
      content: |-
        #import <UIKit/UIKit.h>

        @interface #{full_class_name} : NSObject<NSObject>
          @property (readonly, nonatomic) NSObject* property;

          - (instancetype) init;
          - (BOOL) methodWithBool: (BOOL) boolParameter andObject: (NSObject*) objectParameter;
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
          - (void) #{full_class_name} {
            _instanceVariable = nil;
          }

          - (instancetype) init {
            if(self = [super init]) {
              [self #{full_class_name}];
            }
            return self;
          }

          - (BOOL) methodWithBool: (BOOL) boolParameter andObject: (NSObject*) objectParameter {
            return YES;
          }
        @end

  proto:
    header:
      indent: 0
      content: |-
        #import <UIKit/UIKit.h>

        @protocol #{full_class_name} <NSObject>
          @required
            @property (readonly, nonatomic) NSObject* requiredProperty;
            - (BOOL) requiredMethod: (NSObject*) parameter;

          @optional
            @property (readonly, nonatomic) NSObject* optionalProperty;
            - (BOOL) optionalMethod: (NSObject*) parameter;
        @end

  test:
    body:
      indent: 0
      content: |-
        #import <XCTest/XCTest.h>

        @interface #{full_class_name} : XCTestCase
        @end

        @implementation #{full_class_name}
          - (void) testBasics {
            XCTFail(@"Not implemented");
          }

          - (void) setUp {
            [super setUp];
          }

          - (void) tearDown {
            [super tearDown];
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
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([app_Delegate class]));
          }
        }

  ain:
    like: main

