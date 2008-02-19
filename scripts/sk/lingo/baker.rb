=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'fileutils'

module SK
  module Lingo
    class Baker
      attr_reader :options, :undo_stack

      def initialize(options, *args)
        @options = options
        @undo_stack = args.first
      end

      def guess(name, namespace, extension)
        case extension
          when ''
            cc_header name, namespace, 'h'
            cc_body name, namespace, 'cc'

          when 'h', 'hpp', 'hxx', 'cxx'
            cc_header name, namespace, extension

          when 'cc', 'cpp'
            cc_body name, namespace, extension

          when 'c'
            c name, namespace, extension

          when 'rb'
            ruby name, namespace, extension

          when 'sh'
            sh name, namespace, extension

          else
            raise "Unsupported type #{extension.inspect} for #{name.inspect}"
        end
      end

      def cc_header(name, namespace, extension)
        filename = locator.figure_for 'include', name, extension
        namespace = locator.namespace(namespace)

        save filename, name, namespace, [
          append_newline_if(make_c_comments(make_copyright_notice)),
          make_h_guard(namespace, name, extension) {
            [
              '',
              append_newline_if(make_includes(config.header_includes)),
              make_namespace(namespace) {
                make_class_definition(name)
              },
              '',
              append_newline_if(config.header_bottom)
            ]
          }
        ]
      end

      def cc_body(name, namespace, extension)
        filename = locator.figure_for 'lib', name, extension
        namespace = locator.namespace(namespace)
        scope = (namespace + [ name, '' ]).join('::')

        save filename, name, namespace, [
          make_c_comments(make_copyright_notice),
          prepend_newline_if(make_includes(config.body_includes)),
          prepend_newline_if(make_includes([ locator.header_specification(name, extension) ])),
          prepend_newline_if(config.body_top),
          config.constructors.map { |_constructor|
            [
              '',
              scope,
              "#{name}#{_constructor.parameters}",
              indent(make_initialization_list(config.initializes)),
              '{',
               indent(_constructor.body),
              '}'
            ]
          },
          config.destructors.map { |_destructor|
            [
              '',
              scope,
              "~#{name}()",
              '{',
              indent(_destructor.body),
              '}'
            ]
          },
          (config.public_methods + config.protected_methods + config.private_methods).map { |_method|
            [
              '',
              _method.returns,
              scope,
              _method.signature,
              '{',
              indent(_method.body),
              '}'
            ]
          }
        ]
      end

      def c(name, namespace, extension)
        save "#{name}.#{extension}", name, namespace, [
          make_c_comments(make_copyright_notice),
          prepend_newline_if(make_namespace(namespace))
        ]
      end

      def sh(name, namespace, extension)
        filename = "#{name}.#{extension}"
        save filename, name, namespace, [
          '#!/bin/sh',
          make_pound_comments(make_copyright_notice),
          prepend_newline_if(config.sh)
        ] and FileUtils.chmod 0755, filename
      end

      def ruby(name, namespace, extension)
        save "#{name}.#{extension}", name, namespace, [
          append_newline_if(make_ruby_block_comments(make_copyright_notice)),
          make_ruby_modules(namespace) {
            [
              "class #{ruby_module_name(name)}",
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
            make_ruby_modules(namespace) {
              [
                "class #{ruby_module_name(name)}Test < Test::Unit::TestCase",
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
      end

      private
      #######

      def config
        @config ||= SK::Lingo::Config.new(options)
      end

      def locator
        @locator ||= SK::Lingo::Cpp::Locator.new(options, Dir.pwd)
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

      def make_namespace(namespace, &block)
        block ||= proc {
          []
        }
        return block.call if namespace.empty?
        [
          "namespace #{namespace.first} {",
          indent(
            make_namespace(namespace[1..-1], &block)
          ),
          '}'
        ]
      end

      def decorate(content, &block)
        (block.nil? or content.empty?) ? content : block.call(content)
      end

      def make_class_definition(name)
        [ 
          "class #{name}",
          indent(make_initialization_list(config.extends)),
          '{',
          indent(
            append_newline_if(config.class_init),
            decorate(
              append_newline_if(
                config.constructors.map { |_constructor|
                  "#{name}#{_constructor.parameters};"
                } + 
                config.destructors.map { |_destructor|
                  "#{_destructor.type} ~#{name}();".strip
                }
              ) +
              append_newline_if(make_method_definition(config.public_methods))
            ) { |_out|
              [ 'public:', indent(_out) ]
            },
            decorate(make_method_definition(config.protected_methods)) { |_out| 
              [ 'protected:', indent(_out), '' ]
            },
            'private:',
            indent(
              "#{name}(const #{name}& other);",
              "#{name}& operator = (const #{name}& other);",
              prepend_newline_if(make_method_definition(config.private_methods)),
              prepend_newline_if(config.data)
            )
          ),
          '};'
        ]
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

      def save(file, name, namespace, *content)
        if options.has_key?('print')
          $stderr.puts "=== #{file}"
          output name, namespace, content, $stdout

          false
        else
          File.open(file, file_write_flags) do |_io|
            @undo_stack.add {
              File.unlink(file)
              $stderr.puts "Removed: #{file}"
            }
            output name, namespace, content, _io
          end
          $stderr.puts "Created: #{file}"

          true
        end
      end

      def file_write_flags
        File::CREAT | File::WRONLY | (options['force'] ? File::TRUNC : File::EXCL)
      end

      def output(name, namespace, content, stream)
        substitutions = Hash[
          'FULL_CLASS_NAME' => (namespace + [name]).join('::'),
          'CLASS_NAME' => name,
          'NAMESPACE' => namespace.join('::')
        ]
        pattern = Regexp.new substitutions.keys.map { |_variable|
          Regexp.quote('#{' + _variable + '}')
        }.join('|')

        stream.puts content.flatten.join("\n").gsub(pattern) { |_match|
          substitutions[_match[2...-1]]
        }
      end

      def make_includes(includes)
        return includes if includes.empty?
        includes.map { |_include|
          "#include #{_include}"
        }
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

      def make_method_definition(methods)
        return methods if methods.empty?
        methods.map { |_method|
          [
            _method.comments,
            "#{_method.returns} #{_method.signature};"
          ]
        }
      end

      def indent_prefix
        @indent_prefix ||= (' ' * config.indent)
      end

      def indent(*content)
        content.flatten.map { |_line| indent_prefix + _line } 
      end
       
      def make_initialization_list(content)
        return content if content.empty?
        [ ': ' + content.first, *content[1..-1].map { |_line| '  ' + _line } ]
      end

      def make_h_guard(*args)
        tag = "_#{args.flatten.join('_').upcase}_"
        [
          "#ifndef #{tag}",
          "#define #{tag}",
          yield,
          "#endif /* #{tag} */"
        ]
      end

      def make_pound_comments(lines)
        lines.map { |_line|
          '#  ' + _line
        }
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

      def make_c_comments(lines)
        return lines if lines.empty?

        first, *rest = lines
        return [ "// #{first}" ] if rest.empty?

        [ "/*  #{first}" ] + rest.map { |_line| " *  #{_line}" } + [ '*/' ]
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
        def setup
        end
        
        def teardown
        end
      end
    end
  end
end
