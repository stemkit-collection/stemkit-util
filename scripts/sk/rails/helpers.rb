=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

module SK
  module Rails
    module Helpers
      def render_flash_for(area, options = {}, &block)
        area_tag_class = "#{area}-area"
        block ||= proc { |_class, _content|
          content_tag(:div, :class => _class) {
            _content
          }
        }
        renderer = proc { |_partial|
          render(:partial => "shared/#{_partial}", :object => area.to_sym, :locals => options).to_s.tap { |_content|
            break if _content.strip.empty?
            break escape_javascript _content if options[:js]
          }
        }
        block.call area_tag_class, options[:partial].tap { |_partial|
          break renderer.call _partial unless _partial.nil?
        }
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'

  module SK
    module Rails
      class HelpersTest < Test::Unit::TestCase
          include SK::Rails::Helpers

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
            assert_equal "", render_flash_for(:abc, :partial => :zzz)
          end
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
