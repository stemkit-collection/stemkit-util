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

        def render_update_flash_for(area, options = {}, &block)
          render_flash_for area, options.merge(:js => true) do |element, content|
            <<-EOS
              $('.#{element}').hide('slow');
              $('.#{element}').html('#{content}');
              $('.#{element}').show('slow');
            EOS
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

          def render(options = {})
          end

          def content_tag(name, options = {}, &block)
            "<#{name}>#{block.call}</#{name}>"
          end

          def test_invocation
            assert_equal "", render_update_flash_for(:abc)
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
