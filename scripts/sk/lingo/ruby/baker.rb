# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/baker.rb'
require 'sk/lingo/recipe/content-layout.rb'
require 'sk/lingo/recipe/comments.rb'

module SK
  module Lingo
    module Ruby
      class Baker < SK::Lingo::Baker
        include SK::Lingo::Recipe::ContentLayout
        include SK::Lingo::Recipe::Comments

        def accept(item)
          if enforced? or [ 'rb', nil ].include? item.extension
            proc {
              process(item)
            }
          end
        end

        def process(item)
          save item, make_content(item)
          make_executable item unless item.extension
        end

        def inline_config_locator
          SK::Config::InlineLocator[ read_after_end_marker(__FILE__), super ]
        end

        def ruby_module_name(name)
          File.basename(name).split(%r{[_-]}).map { |_part| _part[0,1].upcase + _part[1..-1] }.join
        end

        def make_qualified_name(*args)
          args.flatten.compact.map { |_item| 
            ruby_module_name(_item.capitalize) 
          }.join('::')
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

        def make_line_comments(*lines)
          make_pound_comments lines
        end

        def make_block_comments(*args)
          lines = args.flatten.compact
          [
            '=begin',
            lines.map { |_line|
              '  ' + _line
            },
            '=end'
          ]
        end

        def make_config(options, data)
          SK::Lingo::Config.new 'ruby', options, data
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
  default:
    indent: 0
    content:
      -
        namespace: true
        content: |-
          class #{class_name}
          end

      -
        header: |-
          if $0 == __FILE__ or defined?(Test::Unit::TestCase)

        content:
          -
            content: |-
              require 'test/unit'
              require 'mocha'
              require 'stubba'
          -
            namespace: true
            content: |-
              class #{class_name}Test < Test::Unit::TestCase
                def setup
                end
              end

        footer: |-
          end

  tsc-app:
    shebang: "#!/usr/bin/env ruby"
    indent: 0
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

            puts "P: " + options.parameter.inspect if options.parameter?
            puts "L: " + options.parameter_list.inspect if options.parameter_list?
            puts "I: " + ARGV.inspect
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
