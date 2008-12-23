# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/baker.rb'
require 'sk/lingo/cpp/locator.rb'
require 'sk/lingo/cpp/recipes.rb'
require 'sk/lingo/cpp/config.rb'

module SK
  module Lingo
    module Cpp
      class Baker < SK::Lingo::Baker
        include SK::Lingo::Cpp::Recipes

        def accept(item)
          case item.extension
            when 'h', 'hpp', 'hxx', 'cxx'
              proc {
                header item
              }

            when 'cc', 'cpp'
              proc {
                body item
              }

            else
              if item.extension.nil? or enforced?
                proc {
                  header item, 'h'
                  body item, 'cc'
                }
              end
          end
        end

        def cpp_item(item, extension, kind)
          TSC::Dataset.new(item, :kind => kind, :extension => (extension || item.extension))
        end

        def header(item, extension = nil)
          namespace = locator.namespace(item.namespace)
          save cpp_item(item, extension, 'include'), [
            append_newline_if(make_comments(make_copyright_notice)),
            make_h_guard(namespace, item.name, item.extension) {
              [
                '',
                append_newline_if(make_includes(config.header_includes)),
                make_namespace(namespace) {
                  make_class_definition(item.name)
                },
                '',
                append_newline_if(config.header_bottom)
              ]
            }
          ]
        end

        def make_filename(item)
          locator.path_for item.kind, super(item)
        end

        def body(item, extension = nil)
          namespace = locator.namespace(item.namespace)
          scope = (namespace + [ item.name, '' ]).join('::')

          save cpp_item(item, extension, 'lib'), [
            make_comments(make_copyright_notice),
            prepend_newline_if(make_includes(config.body_includes)),
            prepend_newline_if(make_includes([ locator.header_specification(item.name, item.extension) ])),
            prepend_newline_if(config.body_top),
            config.constructors.map { |_constructor|
              [
                '',
                scope,
                "#{name}#{_constructor.parameters}",
                indent(make_initialization_list(config.initializes)),
                '{',
                 indent(_constructor.body),
                '}'
              ]
            },
            config.destructors.map { |_destructor|
              [
                '',
                scope,
                "~#{name}()",
                '{',
                indent(_destructor.body),
                '}'
              ]
            },
            (config.public_methods + config.protected_methods + config.private_methods).map { |_method|
              [
                '',
                _method.returns,
                scope,
                _method.signature,
                '{',
                indent(_method.body),
                '}'
              ]
            }
          ]
        end

        def make_namespace(namespace, &block)
          block ||= proc {
            []
          }
          return block.call if namespace.empty?
          [
            "namespace #{namespace.first} {",
            indent(
              make_namespace(namespace[1..-1], &block)
            ),
            '}'
          ]
        end

        def make_class_definition(name)
          [ 
            "class #{name}",
            indent(make_initialization_list(config.extends)),
            '{',
            indent(
              append_newline_if(config.class_init),
              decorate(
                append_newline_if(
                  config.constructors.map { |_constructor|
                    "#{name}#{_constructor.parameters};"
                  } + 
                  config.destructors.map { |_destructor|
                    "#{_destructor.type} ~#{name}();".strip
                  }
                ) +
                append_newline_if(make_method_definition(config.public_methods))
              ) { |_out|
                [ 'public:', indent(_out) ]
              },
              decorate(make_method_definition(config.protected_methods)) { |_out| 
                [ 'protected:', indent(_out), '' ]
              },
              'private:',
              indent(
                "#{name}(const #{name}& other);",
                "#{name}& operator = (const #{name}& other);",
                prepend_newline_if(make_method_definition(config.private_methods)),
                prepend_newline_if(config.private_data_members)
              )
            ),
            '};'
          ]
        end

        def make_includes(includes)
          return includes if includes.empty?
          includes.map { |_include|
            "#include #{_include}"
          }
        end

        def make_method_definition(methods)
          return methods if methods.empty?
          methods.map { |_method|
            [
              _method.comments,
              "#{_method.returns} #{_method.signature};"
            ]
          }
        end

        def make_initialization_list(content)
          return content if content.empty?
          [ ': ' + content.first, *content[1..-1].map { |_line| '  ' + _line } ]
        end

        def inline_config_locator
          SK::Config::InlineLocator[ read_after_end_marker(__FILE__), super ]
        end

        def make_config(options, data)
          SK::Lingo::Cpp::Config.new options, data
        end

        def locator
          @locator ||= SK::Lingo::Cpp::Locator.new(bakery.options, Dir.pwd)
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

cpp:
  header_includes: |

  body_includes: |
    <iostream>
    <iomanip>

  extends: |

  initializes: |

  public_methods:

  protected_methods:

  private_methods:

  data: |

  factory:
    constructor(): |
    destructor(): |

  test:
    class_init: |
      CPPUNIT_TEST_SUITE(#{FULL_CLASS_NAME});
        CPPUNIT_TEST(testSimple);
      CPPUNIT_TEST_SUITE_END();

    header_includes: |
      <cppunit/TestFixture.h>
      <cppunit/extensions/HelperMacros.h>

    body_top: |
      CPPUNIT_TEST_SUITE_REGISTRATION(#{FULL_CLASS_NAME});

    header_bottom: |

    body_includes: |

    extends: |
      public CppUnit::TestFixture

    initializes: |

    public_methods:
      void setUp(): |
      void tearDown(): |
      void testSimple(): |
        CPPUNIT_ASSERT_EQUAL(true, false);

    protected_methods:

    private_methods:

    data: |

    factory:
