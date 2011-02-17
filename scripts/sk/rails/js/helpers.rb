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
        end

        def render_js_common_functions
        end

        def render_flash_functions_for(area, options = {})
          render_flash_for area do |_area, _class, _content|
            SK::Rails::JS::Helpers.normalize_js_block %{
              | function flash#{_area.to_s.capitalize}(content) { 
              |   $('.#{_class}').hide();
              |   $('.#{_class}').html(content == null ? '' : content);
              |   $('.#{_class}').show('fast');
              | }
            }
          end
        end

        def render_flash_update_for(area, options = {})
          render_flash_for area, options.merge(:js => true) do |_area, _class, _content|
            SK::Rails::JS::Helpers.normalize_js_block %{
              | $('.#{_class}').hide('fast');
              | $('.#{_class}').html('#{escape_javascript(_content)}');
              | $('.#{_class}').show('fast');
            }
          end
        end
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
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

          def escape_javascript(content)
            content
          end

          def content_tag(name, options = {}, &block)
            "<#{name}>#{block.call}</#{name}>"
          end

          def OFF_test_invocation
            assert_equal "", render_flash_update_for(:abc, :partial => :zzz)
          end

          def test_normalize
            assert_equal '', SK::Rails::JS::Helpers.normalize_js_block(%{
              | aaa
              |   bbb
              |ccc


            })
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
