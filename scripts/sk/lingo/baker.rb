=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'tsc/errors.rb'
require 'tsc/after-end-reader.rb'
require 'sk/lingo/config.rb'
require 'sk/config/inline-locator.rb'
require 'sk/config/uproot-locator.rb'
require 'sk/config/home-locator.rb'
require 'sk/yaml-config.rb'

require 'fileutils'

module SK
  module Lingo
    class Baker
      attr_reader :bakery

      include TSC::AfterEndReader

      class << self
        include Enumerable

        def list
          targets.map { |_file, _lingo|
            _lingo
          }
        end

        def find(target)
          targets.each do |_file, _lingo|
            return load_lingo(_file, _lingo) if _lingo == target
          end

          raise "Unsupported target language #{target.inspect} (use option --list to see supported)"
        end

        def targets
          Dir[ File.join(File.dirname(__FILE__), '*', 'baker.rb') ].map { |_item|
            [ _item, _item.scan(%r{^.*/(.*?)/baker.rb$}).flatten.compact.first ]
          }
        end

        def each(&block)
          return unless block_given?

          targets.each do |_file, _lingo|
            yield load_lingo(_file, _lingo)
          end
        end

        def load_lingo(file, lingo)
          require file

          [ 'SK', 'Lingo', lingo.capitalize, 'Baker' ].inject(Module) { |_module, _item|
            _module.const_get(_item)
          }
        end
      end

      def initialize(bakery)
        @bakery = bakery
      end

      def accept(item)
        raise TSC::NotImplementedError, :accept
      end

      def config
        @config ||= begin
          make_config bakery.options, SK::YamlConfig[config_locator].data
        end
      end

      def make_config(options, data)
        SK::Lingo::Config.new nil, options, data
      end

      def config_locator
        SK::Config::UprootLocator[ 
          'config/new.yaml', 
          SK::Config::HomeLocator[ 
            '.new.yaml', 
            inline_config_locator 
          ] 
        ]
      end

      def inline_config_locator
        SK::Config::InlineLocator[ read_after_end_marker(__FILE__) ]
      end

      def decorate(content, &block)
        (block.nil? or content.empty?) ? content : block.call(content)
      end

      def serialize(*content)
        content.flatten.compact
      end

      def prepend_newline_if(content)
        content.empty? ? content : [ '', content ]
      end

      def append_newline_if(content)
        content.empty? ? content : [ content, '' ]
      end

      def save(item, *content)
        if bakery.options.print?
          $stderr.puts "=== #{file}"
          output item, content, $stdout

          false
        else
          file = make_filename(item)
          File.open(file, file_write_flags) do |_io|
            bakery.undo.add {
              File.unlink(file)
              $stderr.puts "Removed: #{file}"
            }
            output item, content, _io
          end
          $stderr.puts "Created: #{file}"

          true
        end
      end

      def enforced?
        bakery.options.target == self.class.name.split('::').slice(-2).downcase
      end

      def file_write_flags
        File::CREAT | File::WRONLY | (bakery.options.force? ? File::TRUNC : File::EXCL)
      end

      def make_copyright_notice
        @notice ||= [
          config.copyright_holders.map { |_holder|
            "Copyright (c) #{Time.now.year}, #{_holder}"
          },
          append_newline_if(prepend_newline_if(config.license)),
          config.authors.map { |_author|
            'Author: ' + _author
          }
        ].flatten.compact
      end

      def output(item, content, stream)
        substitutions = Hash[
          'FULL_CLASS_NAME' => make_qualified_name(item.namespace, item.name),
          'CLASS_NAME' => make_qualified_name(item.name),
          'NAMESPACE' => make_qualified_name(item.namespace)
        ]
        pattern = Regexp.new substitutions.keys.map { |_variable|
          Regexp.quote('#{' + _variable + '}')
        }.join('|')

        stream.puts content.flatten.join("\n").gsub(pattern) { |_match|
          substitutions[_match[2...-1]]
        }
      end

      def make_qualified_name(*args)
        args.flatten.compact.map { |_item| _item.capitalize }.join('::')
      end
      
      def indent_prefix
        @indent_prefix ||= (' ' * config.indent)
      end

      def indent(*content)
        content.flatten.map { |_line| indent_prefix + _line } 
      end

      def make_filename(item)
        [ item.name, item.extension ].compact.join('.')
      end

      def make_executable(item)
        FileUtils.chmod 0755, make_filename(item)
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
      class BakerTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end

__END__

indent: 2

copyright_holders: |

authors: |

license: |
