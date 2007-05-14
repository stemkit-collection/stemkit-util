=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'sk/rpc/builder.rb'

module SK
  module RPC
    module Java
      class Builder < SK::RPC::Builder
        def make_xmlrpc(destination)
          puts [
            "=== File #{ [ namespace, wsdl.service ].join('/') }.java ===",
            '',
            append_newline_if(namespace.empty? || "package #{namespace.join('.')};"),
            "public class #{wsdl.service} {",
            indent(
              "public #{wsdl.service}() {",
                indent('// Will connect to the default XML-RPC endpoint taken from WSDL.'),
              '}',
              '',
              "public #{wsdl.service}(String endpoint) {",
                 indent('// Will connect to the specified XML-RPC endpoint.'),
              '}',
              service_methods
            ),
            "}"
          ].compact.flatten
        end

        def service_methods
          wsdl.actions.map { |_name, _info|
            [
              '',
              "public #{typemap[_info[:output]]} #{_name}(#{params(_info[:input])}) {",
              indent(
                '// Generated XML-RPC code to invoke the service with converting',
                '// input and output parameters.',
                %Q{throw new UnsupportedOperationException("#{wsdl.service}##{_name}() not yet implemented.");}
              ),
              '}'
            ]
          }
        end

        def params(input)
          input.map { |_name, _type|
            "#{typemap[_type]} #{_name}"
          }.join(', ')
        end

        def typemap
          @typemap ||= Hash.new { |_hash, _key|
            _hash[_key] = begin
              case _key
                when 'int' then 'Integer'
                when 'string' then 'String'
                when 'boolean' then 'Boolean'
                when 'none' then 'void'
                else infer_native_type(_key)
              end
            end
          }
        end

        def infer_native_type(type)
          wsdl.types.fetch(type).convert(type, self)
        end

        def convert_array(name, item)
          "List<#{typemap[item]}>"
        end

        def convert_pod(name, item)
          normalized = normalize_type(name)
          genereate_pod normalized, item
          normalized
        end

        def normalize_type(type)
          [
            type.slice(0...-1).map { |_component|
              _component.downcase
            }, 
            type.last 
          ].flatten.join('.')
        end

        def genereate_pod(name, data)
          components = name.split('.')
          namespace = components.slice(0...-1)
          puts [
            "=== File #{name.tr('.', '/')}.java ===",
            '',
            append_newline_if(namespace.empty? || "package #{namespace.join('.')};"),
            "public class #{components.last} {",
            indent(
              data.map { |_name, _type|
                "public #{typemap[_type]} #{_name};"
              }
            ),
            '}',
            ''
          ]
        end
      end
    end
  end
end
