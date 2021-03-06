# vim: set sw=2:
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
require 'sk/lingo/substitutor.rb'
require 'sk/config/inline-locator.rb'
require 'sk/config/uproot-locator.rb'
require 'sk/config/home-locator.rb'
require 'sk/yaml-config.rb'

require 'fileutils'
require 'pathname'

module SK
  module Lingo
    class Baker
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
          dirname = File.dirname(__FILE__).tr('\\', '/')
          Dir[ File.join(dirname, '*', 'baker.rb') ].map { |_item|
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

      attr_reader :bakery, :tag
      include TSC::AfterEndReader

      def initialize(tag, bakery)
        @tag, @bakery = tag.to_s, bakery
      end

      def accept(item)
        raise TSC::NotImplementedError, [ self.class.name, :accept ]
      end

      def config
        @config ||= begin
          make_config bakery.options, SK::YamlConfig.new(config_locator, :consolidate => false).data
        end
      end

      def make_config(options, data)
        SK::Lingo::Config.new tag, options, data
      end

      def config_locator
        SK::Config::UprootLocator[
          'config/new.yaml',
          SK::Config::HomeLocator[
            '.new.yaml',
            SK::Config::UprootLocator.new(
              :item => 'config/new.yaml',
              :spot => bakery.location,
              :locator => inline_config_locator
            )
          ]
        ]
      end

      def inline_config_locator
        SK::Config::InlineLocator[ read_after_end_marker(__FILE__) ]
      end

      def make_comments(*lines)
        lines.flatten.compact.size == 1 ? make_line_comments(*lines) : make_block_comments(*lines)
      end

      def make_block_comments(*lines)
        raise TSC::NotImplementedError, [ self.class.name, :make_block_comments ]
      end

      def make_line_comments(*lines)
        raise TSC::NotImplementedError, [ self.class.name, :make_line_comments ]
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

      def make_and_save(section, item)
        config.target[section].tap do |_section|
          save item, make_content(item, _section) if _section
        end
      end

      def save(item, *content)
        file = make_filename(item)
        if bakery.options.print?
          $stderr.puts "=== #{file}"
          output item, content, $stdout
          $stdout.flush

          false
        else
          FileUtils.mkdir_p File.dirname(file)
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
            "Copyright (c) #{Time.now.year} #{_holder}"
          },
          append_newline_if(prepend_newline_if(config.license)),
          config.authors.map { |_author|
            'Author: ' + _author
          }
        ].flatten.compact
      end

      def output(item, content, stream)
        Substitutor.new(item, self).tap do | _substitutor|
          stream.puts content.flatten.map { |_line|
            _substitutor.process _line.sub(%r{\s+$}, '')
          }
        end
      end

      def make_qualified_name(*args)
        args.flatten.compact.map { |_item| _item.capitalize }.join('::')
      end

      def make_item_tag(item)
        [ '', item.namespace, item.name, '' ].flatten.compact.map { |_item| _item.to_s.upcase }.join('_')
      end

      def make_item_reference(item)
        File.join item.namespace, item.name
      end

      def indent_prefix
        @indent_prefix ||= (' ' * config.indent)
      end

      def indent(*content)
        content.flatten.compact.map { |_line| indent_prefix + _line }
      end

      def make_filename(item)
        File.join *[ item.location, [ item.name, item.extension ].compact.join('.') ].flatten
      end

      def make_executable(item)
        unless bakery.options.print?
          FileUtils.chmod 0755, make_filename(item)
        end
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

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

vim: "vim: sw=#{indent}:"

indent: 2

copyright_holders: |

authors: |

license: |

