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
    module Java
      class Builder < SK::RPC::Builder
        include FileUtils

        def make_xmlrpc(destination)
          @destination = destination
          filename = File.join(@destination, namespace, wsdl.service) + '.java'
          mkdir_p File.dirname(filename)

          File.open(filename, 'w') do |_io|
            _io.puts [
              '',
              append_newline_if(namespace.empty? || "package #{namespace.join('.')};"),
              'import java.net.*;',
              'import java.util.*;',
              '',
              'import org.apache.xmlrpc.client.*;',
              'import org.apache.xmlrpc.*;',
              '',
              "public class #{wsdl.service} {",
              indent(
                "public #{wsdl.service}(String endpoint) throws MalformedURLException {",
                 indent(
                   'XmlRpcClientConfigImpl config = new XmlRpcClientConfigImpl();',
                   'config.setServerURL(new URL(endpoint));',
                   '_client = new XmlRpcClient();',
                   '_client.setConfig(config);'
                 ),
                '}',
                '',
                "public #{wsdl.service}() throws MalformedURLException {",
                 indent(
                   %Q{this("#{wsdl.endpoint}");}
                 ),
                '}',
                '',
                'public String endpoint() {',
                indent(
                  %Q{return "#{wsdl.endpoint}";}
                ),
                '}',
                service_methods,
                '',
                'private XmlRpcClient _client;'
              ),
              "}"
            ].flatten.compact

          end
          puts filename
        end

        def service_methods
          wsdl.actions.map { |_name, _info|
            [
              '',
              "public #{typemap[_info[:output]]} #{_name}(#{params(_info[:input])}) throws XmlRpcException, ClassCastException {",
              indent(
                'Vector<Object> params = new Vector<Object>();',
                _info[:input].map { |_parameter, _type|
                  %Q{params.addElement(#{_parameter});}
                },
                '',
                %Q{Object result = _client.execute("#{_name}", params);},
                unless _info[:output] == 'none'
                  [ 
                    "#{typemap[_info[:output]]} value = (#{typemap[_info[:output]]})result;",
                    "return value;"
                  ]
                end
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
          "java.util.List<#{typemap[item]}>"
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

          filename = File.join(@destination, components) + '.java'
          mkdir_p File.dirname(filename)

          File.open(filename, "w") do |_io|
            _io.puts [
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
          puts filename
        end
      end
    end
  end
end
