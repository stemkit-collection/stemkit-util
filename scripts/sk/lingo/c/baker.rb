=begin
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
          save item, [
            make_comments(make_copyright_notice),
            ''
          ]
        end

        def header(item, extension = nil)
          save item, [
            append_newline_if(make_comments(make_copyright_notice)),
            make_h_guard(item.namespace, item.name, item.extension) {
              [
                '',
                make_cpp_guard {
                  ''
                },
                ''
              ]
            }
          ]
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
