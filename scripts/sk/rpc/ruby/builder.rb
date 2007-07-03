=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'sk/rpc/builder.rb'
require 'fileutils'

module SK
  module RPC
    module Ruby
      class Builder < SK::RPC::Builder
        include FileUtils

        def make_xmlrpc(destination)
          @destination = destination

          filename = File.join(@destination, ruby_file_name(namespace, wsdl.service)) + '.rb'
          mkdir_p File.dirname(filename)

          File.open(filename, 'w') do |_io|
            _io.puts [
              '',
              'require "xmlrpc/client"',
              '',
              make_ruby_modules(namespace) {
                [
                  "class #{wsdl.service}",
                  indent(
                    "def initialize(endpoint = nil)",
                    indent(
                      "@client = XMLRPC::Client.new2(endpoint || #{wsdl.endpoint.inspect})"
                    ),
                    'end',
                    '',
                    'def endpoint',
                    indent(
                      "'#{wsdl.endpoint}'"
                    ),
                    'end',
                    service_methods
                  ),
                  'end'
                ]
              }
            ].flatten.compact
          end
          puts filename
        end

        def service_methods
          wsdl.actions.map { |_name, _info|
            return_type = _info[:output]
            params = _info[:input].map { |_parameter, _type| _parameter }
            [
              '',
              "def #{ruby_method_name(_name)}(#{params.join(', ')})",
              indent(
                wsdl.types.fetch(return_type).upcast(self, return_type, "@client.call(#{[ _name.inspect, *params ].join(', ')})")
              ),
              'end'
            ]
          }
        end

        def generate_pod(name, data)
          components = name.split('::')
          namespace = components.slice(0...-1)
          pod = components.last

          filename = File.join(@destination, ruby_file_name(namespace, pod)) + '.rb'
          mkdir_p File.dirname(filename)

          File.open(filename, "w") do |_io|
            _io.puts [
              make_ruby_modules(namespace) {
                [
                  "class #{pod}",
                  indent(
                    "def initialize(data)",
                    indent(
                      '@data = data'
                    ),
                    'end',
                    '',
                    "def to_s",
                    indent(
                      "'#{name}: ' + @data.inspect"
                    ),
                    'end',
                    '',
                    data.map { |_name, _type|
                      type = typemap[_type]
                      upcastor = wsdl.types.fetch(_type)
                      [
                        "def #{_name}",
                        indent(
                          upcastor.upcast(self, type, "@data['#{_name}']")
                        ),
                        'end',
                        ''
                      ]
                    }
                  ),
                  'end'
                ]
              }
            ]
          end
          puts filename
        end

        def upcast_builtin(type, statement, &block)
          block ||= proc { |_result|
            _result
          }
          block.call(statement)
        end

        def upcast_pod(type, members, statement, &block)
          pod_type = typemap[type]
          block ||= proc { |_result|
            _result
          }
          block.call [
            "require #{File.join(ruby_file_name(pod_type.split('::'))).inspect}",
            "#{pod_type}.new(#{statement})"
          ]
        end

        def upcast_array(type, statement, &block)
          array_type = typemap[type]
          [
            "#{statement}.map { |_item|",
            indent(
              wsdl.types.fetch(type).upcast(self, type, '_item')
            ),
            '}'
          ]
        end

        def upcast_bignum(statement, &block)
          [
            "#{statement}.map.inject(0) { |_number, _item|",
            indent(
              '(_number << 32) | (_item & 0xffffffff)'
            ),
            '}'
          ]
        end

        def convert_bignum
          ''
        end

        def convert_array(type)
          ''
        end

        def upcast_none(statement)
          statement
        end

        def normalize_type(type)
          [
            type.slice(0...-1).map { |_component|
              _component.capitalize
            }, 
            type.last 
          ].flatten.join('::')
        end

        def convert_builtin(type)
          case type
            when 'int' then 'Integer'
            when 'string' then 'String'
            when 'boolean' then 'Boolean'
            when 'dateTime' then 'Date'
            else 
              raise "Unsupported native type #{type.inspect}"
          end
        end

        def ruby_module_name(name)
          join_capitalized_but_first '', *extract_name_components(File.basename(name))
        end

        def ruby_file_name(*args)
          args.flatten.map { |_item|
            extract_name_components(_item).join('-')
          }
        end

        def ruby_method_name(name)
          extract_name_components(name).join('_')
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
      end
    end
  end
end

