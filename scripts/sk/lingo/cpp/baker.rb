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

require 'sk/lingo/cpp/locator.rb'
require 'sk/lingo/cpp/recipes.rb'

module SK
  module Lingo
    module Cpp
      class Baker < SK::Lingo::Baker
        include SK::Lingo::Cpp::Recipes
        include SK::Lingo::Recipe::ContentLayout
        
        def initialize(*args)
          super :cpp, *args
        end

        def accept(item)
          accept_by_extension(item) or begin
            if item.extension.nil? or enforced?
              accept_default(item)
            end
          end
        end

        def accept_by_extension(item)
          case item.extension
            when 'h', 'hpp'
              proc {
                header item, :h
              }

            when 'cpp'
              proc {
                body item, :cc
              }
          end
        end

        def accept_default(item)
          proc {
            header item, :h, 'h'
            body item, :cc, 'cpp'
          }
        end

        def cpp_item(item, extension, kind)
          TSC::Dataset.new item, Hash[
            :kind => kind, 
            :extension => (extension || item.extension),
            :namespace => locator.namespace(item.namespace)
          ]
        end

        def make_filename(item)
          locator.path_for item.kind, super(item)
        end

        def header(item, section, extension = nil)
          item = cpp_item item, extension, 'include'
          save item, make_content(item, config.target[section] || {})
        end

        def body(item, section, extension = nil)
          item = cpp_item item, extension, 'lib'
          save item, make_content(item, config.target[section] || {})
        end

        def make_modules(namespace, &block)
          block ||= proc {
            []
          }
          return block.call if namespace.empty?
          [
            "namespace #{namespace.first} {",
            indent(
              make_modules(namespace[1..-1], &block)
            ),
            '}'
          ]
        end

        def inline_config_locator
          SK::Config::InlineLocator[ read_after_end_marker(__FILE__), super ]
        end

        def make_qualified_name(*args)
          args.flatten.compact.join('::')
        end

        def make_item_tag(item)
          [ '', item.namespace, item.name, item.extension, '' ].flatten.compact.map { |_item| _item.to_s.upcase }.join('_')
        end

        def make_item_reference(item, extension)
          locator.header_specification(item.name, extension)
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
  default:
    h:
      indent: 0
      content:
        - 
          content: |-
            #ifndef #{class_tag}
            #define #{class_tag}

        -
          namespace: true
          content: |-
            class #{class_name} 
            {
              public:
                #{class_name}();
                ~#{class_name}();

              private:
                #{class_name}(const #{class_name}& other);
                #{class_name}& operator = (const #{class_name}& other);
            };

        - 
          content: |-
            #endif /* #{class_tag} */

    cc:
      indent: 0
      content: |-
        #include #{class_reference(:h)}

        #{full_class_name}::
        #{class_name}()
        {
        }

        #{full_class_name}::
        ~#{class_name}()
        {
        }

  main:
    cc:
      indent: 0
      content: |-
        #include <iostream>
        #include <iomanip>
        #include <exception>
        #include <string>

        int main(int argc, const char* argv[])
        {
          try {
            throw std::string("Hello, world!!!");
          }
          catch(const std::exception& exception) {
            std::cerr << "E: " << exception.what() << std::endl;
          }
          catch(const std::string& message) {
            std::cout << message << std::endl;
          }
          catch(...) {
            std::cerr << "Unknown error" << std::endl;
          }
        }
  ain: 
    like: main

    h:

  sk-default:
    h:
      indent: 0
      content:
        - 
          content: |-
            #ifndef #{class_tag}
            #define #{class_tag}
          
            #include <sk/util/Object.h>

        -
          namespace: true
          content: |-
            class #{class_name} 
              : public virtual sk::util::Object
            {
              public:
                #{class_name}();
                virtual ~#{class_name}();

                // sk::util::Object re-implementation.
                const sk::util::Class getClass() const;

              private:
                #{class_name}(const #{class_name}& other);
                #{class_name}& operator = (const #{class_name}& other);
            };

        - 
          content: |-
            #endif /* #{class_tag} */

    cc:
      indent: 0
      content: |-
        #include <sk/util/Class.h>
        #include <sk/util/String.h>

        #include #{class_reference(:h)}

        #{full_class_name}::
        #{class_name}()
        {
        }

        #{full_class_name}::
        ~#{class_name}()
        {
        }

        const sk::util::Class
        #{full_class_name}::
        getClass() const
        {
          return sk::util::Class("#{full_class_name}");
        }
        
  cppunit-test:
    h:
      indent: 0
      content:
        -
          content: |-
            #ifndef #{class_tag}
            #define #{class_tag}

            #include <cppunit/TestFixture.h>
            #include <cppunit/extensions/HelperMacros.h>

        - 
          namespace: true
          content: |-
              class #{class_name}
                : public CppUnit::TestFixture
              {
                CPPUNIT_TEST_SUITE(#{full_class_name});
                  CPPUNIT_TEST(testBasics);
                CPPUNIT_TEST_SUITE_END();
                
                public:
                  #{class_name}();
                  virtual ~#{class_name}();
                  
                  void setUp();
                  void tearDown();
                  void testBasics();
                  
                private:
                  #{class_name}(const #{class_name}& other);
                  #{class_name}& operator = (const #{class_name}& other);
              };

        -
          content: |-
            #endif /* #{class_tag} */

    cc:
      indent: 0
      content: |-
        #include #{class_reference(:h)}

        CPPUNIT_TEST_SUITE_REGISTRATION(#{full_class_name});

        #{full_class_name}::
        #{class_name}()
        {
        }

        #{full_class_name}::
        ~#{class_name}()
        {
        }

        void
        #{full_class_name}::
        setUp()
        {
        }

        void
        #{full_class_name}::
        tearDown()
        {
        }

        void
        #{full_class_name}::
        testBasics()
        {
          CPPUNIT_ASSERT_EQUAL(true, false);
        }

  cppunit-sk-suite:
    cc:
      indent: 0
      content: |-
        #include <cppunit/extensions/TestFactoryRegistry.h>
        #include <sk/cppunit/TestRunner.h>
        #include <sk/cppunit/SourcePath.h>

        #include <iostream>

        int main(int argc, const char* argv[])
        {
          CppUnit::TestFactoryRegistry &registry = CppUnit::TestFactoryRegistry::getRegistry();
          sk::cppunit::TestRunner runner;

          if(argc == 2) {
            sk::cppunit::SourcePath::setBase(argv[1]);
          }
          runner.addTest(registry.makeTest());
          return !runner.run();
        }
