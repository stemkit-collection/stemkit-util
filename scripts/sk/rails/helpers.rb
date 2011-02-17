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
      class << self
        def with_locals_for_partial_or_nil(options, &block)
          locals = options.dup
          partial = locals.delete(:partial).tap { |_partial|
            shared = locals.delete(:shared_partial)
            break "shared/#{shared}" if shared and _partial.nil?
          }
          block.call partial, locals unless partial.nil?
        end
      end

      def sk_render_for_area(area, options = {}, &block)
        raw Array(area).map { |_area|
          area_tag_class = "#{_area}-area"
          block ||= proc { |_area, _class, _content|
            content_tag :div, _content.to_s, :class => _class
          }
          block.call _area, area_tag_class, SK::Rails::Helpers.with_locals_for_partial_or_nil(options) { |_partial, _locals|
            render(:partial => _partial.to_s, :object => _area.to_sym, :locals => _locals).to_s.tap { |_content|
              break if _content.strip.empty?
            }
          }
        }.compact.join("\n")
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

        def raw(content)
          content
        end

        def content_tag(name, content_or_options = {}, options = {}, &block)
          {}.tap { |_options, _content|
            if Hash === content_or_options
              _options.update content_or_options 
              _content = block.call if block
            else
              _content = content_or_options
            end

            params = _options.merge(options).map { |_key, _value|
              "#{_key}=#{_value.inspect}"
            }.join(" ")

            break "<#{name} #{params}>#{_content}</#{name}>"
          }
        end

        def test_invocation
          assert_equal "", sk_render_for_area(:abc, :o => 23, :shared_partial => :uuu)
        end

        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
