=begin
  vim: set sw=2:
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/lingo/m/baker.rb'

module SK
  module Lingo
    module Mp
      class Baker < SK::Lingo::M::Baker

        def tag
          'mp'
        end

        def accept_by_extension(item)
          case item.extension
            when 'h'
              proc {
                header item, :header
              }
          end
        end

        def accept_default(item)
          proc {
            header item, :header, 'h'
          }
        end

        def inline_config_locator
          SK::Config::InlineLocator[ read_after_end_marker(__FILE__), super ]
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

mp:
  source-indent: 2
  indent: 4
  default:
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
