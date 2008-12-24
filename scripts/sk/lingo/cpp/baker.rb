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
require 'sk/lingo/cpp/config.rb'

module SK
  module Lingo
    module Cpp
      class Baker < SK::Lingo::Baker
        include SK::Lingo::Cpp::Recipes
        include SK::Lingo::Recipe::ContentLayout

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
          TSC::Dataset.new item, Hash[
            :kind => kind, 
            :extension => (extension || item.extension),
            :namespace => locator.namespace(item.namespace)
          ]
        end

        def make_filename(item)
          locator.path_for item.kind, super(item)
        end

        def header(item, extension = nil)
          item = cpp_item item, extension, 'include'
          save item, make_content(item, config.target['h'] || {})
        end

        def body(item, extension = nil)
          item = cpp_item item, extension, 'lib'
          save item, make_content(item, config.target['cc'] || {})
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

        def make_config(options, data)
          SK::Lingo::Cpp::Config.new options, data
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
        
