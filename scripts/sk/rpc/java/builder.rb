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
            return_type = _info[:output]
            [
              '',
              "public #{typemap[return_type]} #{_name}(#{params(_info[:input])}) throws XmlRpcException, ClassCastException {",
              indent(
                'Vector<Object> params = new Vector<Object>();',
                _info[:input].map { |_parameter, _type|
                  %Q{params.addElement(#{_parameter});}
                },
                '',
                wsdl.types.fetch(return_type).upcast(self, return_type, %Q{_client.execute("#{_name}", params)})
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
            _hash[_key] = wsdl.types.fetch(_key).convert(self, _key)
          }
        end

        def upcast_pod(type, members, statement, &block)
          pod_type = typemap[type]
          block ||= proc { |_result|
            "return #{_result};"
          }
          [ 
            "HashMap map = (HashMap)#{statement};",
            "#{pod_type} pod = new #{pod_type}();",
            block.call('pod')
          ]
        end

        def upcast_array(type, statement, &block)
          array_type = typemap[type]
          block ||= proc { |_result|
            "return #{_result};"
          }
          upcastor = wsdl.types.fetch(type)
          [
            "List<Object> result = Arrays.asList((Object[])#{statement});",
            'Iterator<Object> iterator = result.iterator();',
            "ArrayList<#{array_type}> array = new ArrayList<#{array_type}>();",
            '',
            'while(iterator.hasNext()) {',
            indent(
              upcastor.upcast(self, type, "iterator.next()") { |_result|
                "array.add(#{_result});"
              }
            ),
            '}',
            block.call('array')
          ]
        end

        def upcast_builtin(type, statement, &block)
          block ||= proc { |_result|
            "return #{_result};"
          }
          block.call "(#{convert_builtin(type)})#{statement}"
        end
        
        def upcast_none(statement)
          "#{statement};"
        end

        def convert_array(type)
          "java.util.List<#{typemap[type]}>"
        end

        def convert_builtin(type)
          case type
            when 'int' then 'Integer'
            when 'string' then 'String'
            when 'boolean' then 'Boolean'
          end
        end

        def convert_none
          'void'
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
                "public String toString() {",
                indent(
                  %Q{return "#{name}: " + #{java_inspect(data)};}
                ),
                '}',
                '',
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

        def java_inspect(members)
          members.map { |_name, _type|
            %Q{"#{_name}=" + this.#{_name}}
          }.join(' + ", " +')
        end
      end
    end
  end
end
