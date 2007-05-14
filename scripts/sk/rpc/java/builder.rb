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

        def convert_data(name, item)
          normalize_type(name)
        end

        def normalize_type(type)
          [
            type.slice(0...-1).map { |_component|
              _component.downcase
            }, 
            type.last 
          ].flatten.join('.')
        end
      end
    end
  end
end
