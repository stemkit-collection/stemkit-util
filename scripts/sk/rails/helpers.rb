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
      def render_flash_for(area, locals = {}, &block)
        area_tag_class = "#{area}-area"
        block ||= proc { |_class, _content|
          content_tag :div, :class => _class {
            _content
          }
        }
        block.call area_tag_class, render(:partial => "shared/flashing", :object => area.to_sym, :locals => locals).to_s
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
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
