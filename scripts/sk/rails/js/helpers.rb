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

        def render_flash_with_js_for(area, options = {}, &block)
          render_flash_for area do |_area, _class, _content|
            content_for _class do
              javascript_tag do
                %{
                  function flash#{_area.to_s.capitalize}() { 
                     alert('#{_area.inspect}'); 
                  }
                }
              end
            end
          end

          render_flash_for(area, options)
        end

        def render_flash_update_for(area, options = {}, &block)
          render_flash_for area, options.merge(:js => true) do |_area, _class, _content|
            [].tap { |_array|
              _array << "$('.#{_class}').hide('fast')"
              _array << "$('.#{_class}').html('#{escape_javascript(_content)}')"
              _array << "$('.#{_class}').show('fast')" if _content

              break _array.push('').join(";\n")
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

          def test_invocation
            assert_equal "", render_flash_update_for(:abc, :partial => :zzz)
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
