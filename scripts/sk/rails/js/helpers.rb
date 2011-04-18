=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/rails/helpers'

module SK
  module Rails
    module JS
      module Helpers
        include SK::Rails::Helpers

        class << self
          def normalize_js_block(content)
            Array(content).map { |_line|
              _line.slice %r{^(\s*\| )(.*$)}, 2
            }.compact.join("\n")
          end

          def capitalize_components(area)
            area.to_s.split(%r{[\W_]}).map { |_component|
              _component.strip.tap { |_item|
                break if _item.empty?
                break _item.capitalize
              }
            }.join
          end
        end

        def sk_render_js_common_functions
          SK::Rails::JS::Helpers.normalize_js_block %{
            | function updateAreaElement(element, content) { 
            |   var target = $('.' + element);
            |   target.hide();
            |   if(content == null) {
            |     target.html('');
            |     return;
            |   }
            |   target.html(content);
            |   target.show('fast');
            | }
          }
        end

        def sk_render_js_functions_for_area(area, options = {})
          sk_render_for_area area do |_area, _class, _content|
            SK::Rails::JS::Helpers.normalize_js_block %{
              | function update#{SK::Rails::JS::Helpers.capitalize_components(_area)}Area(content) { 
              |   updateAreaElement('#{_class}', content);
              | }
            }
          end
        end

        def sk_render_js_update_for_area(area, options = {})
          sk_render_for_area area, options.merge(:js => true) do |_area, _class, _content|
            content = _content ? "'#{escape_javascript(_content)}'" : 'null';
            SK::Rails::JS::Helpers.normalize_js_block %{
              | updateAreaElement('#{_class}', #{content});
            }
          end
        end
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'

  module SK
    module Rails
      module JS
        class HelpersTest < Test::Unit::TestCase
          include SK::Rails::JS::Helpers

          def render(*args)
            args.inspect
          end

          def raw(content)
            content
          end

          def escape_javascript(content)
            content
          end

          def content_tag(name, options = {}, &block)
            "<#{name}>#{block.call}</#{name}>"
          end

          def test_invocation
            assert_equal "", sk_render_js_update_for_area(:abc, :partial => :zzz)
          end

          def test_normalize
            assert_equal '', SK::Rails::JS::Helpers.normalize_js_block(%{

              | aaa
              |   bbb
              |  ccc

            })
          end

          def test_js_functions
            assert_equal "", sk_render_js_functions_for_area(".message-_.request.  zzz")
          end

          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
