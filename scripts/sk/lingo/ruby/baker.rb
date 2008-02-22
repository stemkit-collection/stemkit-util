=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/baker.rb'

module SK
  module Lingo
    module Ruby
      class Baker < SK::Lingo::Baker
        def accept(item)
          case item.extension
            when 'rb'
              process(item)

            else
              return false
          end

          true
        end

        def process(item)
          save item, [
            append_newline_if(make_ruby_block_comments(make_copyright_notice)),
            make_ruby_modules(item.namespace) {
              [
                "class #{ruby_module_name(item.name)}",
                'end'
              ]
            },
            '',
            'if $0 == __FILE__ or defined?(Test::Unit::TestCase)',
            indent(
              "require 'test/unit'",
              "require 'mocha'",
              "require 'stubba'",
              '',
              make_ruby_modules(item.namespace) {
                [
                  "class #{ruby_module_name(item.name)}Test < Test::Unit::TestCase",
                  indent(
                    'def setup',
                    'end',
                    '',
                    'def teardown',
                    'end'
                  ),
                  'end'
                ]
              }
            ),
            'end'
          ]
          
          make_executable item unless item.extension
        end

        def embedded_data
          [ read_after_end_marker(__FILE__), *super ]
        end

        def ruby_module_name(name)
          File.basename(name).split(%r{[_-]}).map { |_part| _part[0,1].upcase + _part[1..-1] }.join
        end

        def make_ruby_modules(namespace, &block)
          return block.call if namespace.empty?
          [
            "module #{ruby_module_name(namespace.first)}",
            indent(
              make_ruby_modules(namespace[1..-1], &block)
            ),
            'end'
          ]
        end

        def make_ruby_block_comments(lines)
          [
            '=begin',
            lines.map { |_line|
              '  ' + _line
            },
            '=end'
          ]
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
      module Ruby
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
ruby:
