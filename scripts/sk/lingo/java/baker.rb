# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/baker.rb'
require 'sk/lingo/recipe/content-layout.rb'
require 'sk/lingo/cpp/recipes.rb'

module SK
  module Lingo
    module Java
      class Baker < SK::Lingo::Baker
        include SK::Lingo::Recipe::ContentLayout
        include SK::Lingo::Cpp::Recipes

        def initialize(*args)
          super :java, *args
        end

        def accept(item)
          if enforced? or [ 'java', nil ].include? item.extension
            proc {
              process(item)
            }
          end
        end

        def process(item)
          save item, make_content(item)
        end

        def inline_config_locator
          SK::Config::InlineLocator[ read_after_end_marker(__FILE__), super ]
        end

        def make_qualified_name(*args)
          args.flatten.compact.join('.')
        end

        def make_modules(namespace, &block)
          [
            unless namespace.empty?
              [
                "package " + make_qualified_name(namespace) + ";",
                ""
              ]
            end,
            block.call
          ]
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
      module Java
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

java:
  indent: 4
  default:
    indent: 0
    content:
      -
        namespace: true
        content: |-
          class #{class_name} {
            public #{class_name}() {
            }
          }

  main:
    indent: 0
    content:
      -
        namespace: true
        content: |-
          public final class #{class_name} {
            public static void main(final String[] args) {
              #{class_name} app = new #{class_name}(args);
              try {
                app.process();
              }
              catch(Exception error) {
                System.err.println("E: " + error.getMessage());
              }
            }

            #{class_name}(final String[] args) {
              _args = args;
            }

            private void process() {
              System.out.println("Hello, world!!!");
            }

            private String[] _args;
          }

  ain:
    like: main
