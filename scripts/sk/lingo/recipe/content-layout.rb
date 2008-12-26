# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'tsc/dataset.rb'

module SK
  module Lingo
    module Recipe
      module ContentLayout
        def make_content(item, top = nil)
          [
            config.shebang,
            append_newline_if(make_comments(config.vim, make_copyright_notice)),

            map_content(top || config.target) { |_entry|
              content = _entry.content
              if _entry.namespace
                content = make_modules(item.namespace) {
                  content
                }.flatten.compact
              end

              _entry.indent.times do
                content = indent(content)
              end

              content
            }
          ]
        end

        def map_content_item(indent, namespace, content)
          yield TSC::Dataset[
            :indent => indent, :namespace => namespace, :content => config.lines(content) 
          ]
        end

        def map_content(entry, indent = 0, &block)
          content = entry['content']
          header = entry['header']
          footer = entry['footer']
          gap = (entry['gap'] || 1).to_s.to_i

          [
            map_content_item(indent, false, header, &block),
            case content
              when Array
                intersperse gap, *content.map { |_content|
                  map_content(_content, indent + (entry['indent'] || 1).to_i, &block)
                }
              else
                map_content_item(indent, entry['namespace'], content, &block)
            end,
            map_content_item(indent, false, footer, &block)
          ]
        end

        private
        #######
        
        def intersperse(gap, content, *rest)
          return [ content, *rest ] unless gap > 0 and rest.empty? == false
          [ content, [ '' ] * gap, *intersperse(gap, *rest) ]
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
      module Recipe
        class ContentLayoutTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
