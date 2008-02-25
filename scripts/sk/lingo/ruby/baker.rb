=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/baker.rb'
require 'sk/lingo/recipes.rb'
require 'sk/lingo/ruby/config.rb'

module SK
  module Lingo
    module Ruby
      class Baker < SK::Lingo::Baker
        include SK::Lingo::Recipes

        def accept(item)
          if enforced? or [ 'rb', nil ].include? item.extension
            proc {
              process(item)
            }
          end
        end

        def process(item)
          save item, [
            config.shebang,
            append_newline_if(make_block_comments(make_copyright_notice)),
            config.map_each_chunk { |_chunk|
              content = _chunk.content
              if _chunk.namespace
                content = make_modules(item.namespace) {
                  content
                }
              end

              _chunk.indent.times do
                content = indent(content)
              end

              _chunk.newline ? append_newline_if(content) : content
            }
          ]

          make_executable item unless item.extension
        end

        def inline_config_locator
          SK::Config::InlineLocator[ read_after_end_marker(__FILE__), super ]
        end

        def ruby_module_name(name)
          File.basename(name).split(%r{[_-]}).map { |_part| _part[0,1].upcase + _part[1..-1] }.join
        end

        def make_modules(namespace, &block)
          return block.call if namespace.empty?
          [
            "module #{ruby_module_name(namespace.first)}",
            indent(
              make_modules(namespace[1..-1], &block)
            ),
            'end'
          ]
        end

        def make_block_comments(lines)
          [
            '=begin',
            lines.map { |_line|
              '  ' + _line
            },
            '=end'
          ]
        end

        def make_config(options, data)
          SK::Lingo::Ruby::Config.new options, data
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
          attr_reader :bakery

          def test_enforced
            baker = Baker.new bakery
            bakery.expects(:options).returns mock('options', :target => 'ruby')
            assert_equal true, baker.enforced? 
          end

          def setup
            @bakery = mock('bakery')
          end
        end
      end
    end
  end
end

__END__
ruby:
  content: 
    -
      namespace: true
      content: |
        class #{CLASS_NAME}
        end
    -
      content: |
        if $0 == __FILE__ or defined?(Test::Unit::TestCase)
          require 'test/unit'
          require 'mocha'
          require 'stubba'
    - 
      indent: 1
      namespace: true
      newline: false
      content: |
        class #{CLASS_NAME}Test < Test::Unit::TestCase
          def setup
          end
        end
    - 
      content: |
        end

  app:
    shebang: "#!/usr/bin/env ruby"
    content: |
      $:.concat ENV['PATH'].to_s.split(File::PATH_SEPARATOR)

      require 'tsc/application.rb'
      require 'tsc/path.rb'

      class Application < TSC::Application
        def initialize
          super { |_config|
            _config.arguments = '<items> ...'
            _config.options = [
              [ '--parameter', 'A parameter', 'name', '-p', '-n' ],
              [ '--test', 'Run internal tests', nil ]
            ]
            _config.description = [
              "It is just a template"
            ]
          }
        end

        def start
          handle_errors {
            process_command_line

            throw :TEST if options.test?
            raise TSC::UsageError, 'Nothing to do' if ARGV.empty?

            puts "P: #{options.parameter.inspect}" if options.parameter?
            puts "L: #{options.parameter_list.inspect}" if options.parameter_list?
            puts "I: #{ARGV.inspect}"
          }
        end

        in_generator_context do |_content|
          _content << '#!' + figure_ruby_path
          _content << '$VERBOSE = nil'
          _content << TSC::PATH.current.front(File.dirname(figure_ruby_path)).to_ruby_eval
          _content << IO.readlines(__FILE__).slice(1..-1)
        end
      end

      unless defined? Test::Unit::TestCase
        catch :TEST do
          Application.new.start
          exit 0
        end
      end

      require 'rubygems'
      require 'test/unit'

      require 'mocha'
      require 'stubba'

      class ApplicationTest < Test::Unit::TestCase
        attr_reader :app

        def test_nothing
        end

        def setup
          @app = Application.new
        end
      end
