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
              normalize_lines('
                import java.net.*;
                import java.util.*;

                import org.apache.xmlrpc.client.*;
                import org.apache.xmlrpc.*;
              '),
              '',
              "public class #{wsdl.service} {",
              indent(
                normalize_lines('
                  public interface DriverFactory {
                    public Driver getDriver(String endpoint) throws MalformedURLException;
                  }

                  public interface Driver {
                    public Object execute(String methodName, List params) throws DriverException;
                  }
                  
                  public class DriverException extends Exception {
                    public DriverException(Exception original) {
                      _original = original;
                    }

                    public String toString() {
                      return _original.toString();
                    }

                    public String getMessage() {
                      return _original.getMessage();
                    }

                    private Exception _original;
                  }
                '),
                '',
                "public #{wsdl.service}(String endpoint) throws MalformedURLException {",
                 indent(
                   '_driver = getDriverFactory().getDriver(endpoint);'
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
                normalize_lines('
                  public static void setDriverFactory(DriverFactory factory) {
                    _driverFactory = factory;
                  }
                  
                  private DriverFactory getDriverFactory() {
                    if(_driverFactory == null) {
                      _driverFactory = new DriverFactory() {
                        public Driver getDriver(String endpoint) throws MalformedURLException {
                          XmlRpcClientConfigImpl config = new XmlRpcClientConfigImpl();
                          config.setServerURL(new URL(endpoint));

                          final XmlRpcClient client = new XmlRpcClient();
                          client.setConfig(config);

                          return new Driver() {
                            public Object execute(String service, List params) throws DriverException {
                              try {
                                return _client.execute(service, params);
                              }
                              catch(XmlRpcException exception) {
                                throw new DriverException(exception);
                              }
                            }
                            private XmlRpcClient _client = client;
                          };
                        }
                      };
                    }
                    return _driverFactory;
                  }
                  
                  private static DriverFactory _driverFactory;
                  private Driver _driver;
                ')
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
              "public #{typemap[return_type]} #{java_method(_name)}(#{params(_info[:input])}) throws DriverException, ClassCastException {",
              indent(
                'Vector<Object> params = new Vector<Object>();',
                _info[:input].map { |_parameter, _type|
                  %Q{params.addElement(#{_parameter});}
                },
                '',
                wsdl.types.fetch(return_type).upcast(self, return_type, %Q{_driver.execute("#{_name}", params)})
              ),
              '}'
            ]
          }
        end

        def normalize_lines(arg)
          sizes, lines = arg.strip.map { |_line|
            [ (_line.slice(%r{^\s*(?=\S)}) or '').size, _line.chomp ]
          }.transpose

          offset = sizes.reject { |_number| _number.zero? }.min

          lines.map { |_line|
            _line.sub %r{^#{' ' * offset}}, ''
          }
        end

        def params(input)
          input.map { |_name, _type|
            "#{typemap[_type]} #{_name}"
          }.join(', ')
        end

        def upcast_pod(type, members, statement, &block)
          pod_type = typemap[type]
          block ||= proc { |_result|
            "return #{_result};"
          }
          block.call("new #{pod_type}((HashMap)#{statement})")
        end

        def upcast_array(type, statement, &block)
          array_type = typemap[type]
          block ||= proc { |_result|
            "return #{_result};"
          }
          upcastor = wsdl.types.fetch(type)
          [
            "Object[] result = (Object[])#{statement};",
            "ArrayList<#{array_type}> array = new ArrayList<#{array_type}>();",
            '',
            'for(Object object : result) {',
            indent(
              upcastor.upcast(self, type, 'object') { |_result|
                "array.add(#{_result});"
              }
            ),
            '}',
            block.call('array')
          ]
        end

        def upcast_bignum(statement, &block)
          block ||= proc { |_result|
            "return #{_result};"
          }
          [
            "Object[] result = (Object[])#{statement};",
            'if(result.length == 0) {', 
            indent(
              'return 0L;'
            ),
            '}',
            'Long bignum = (((Integer)result[1]).longValue() << 32) | (((Integer)result[0]).longValue() & 0xffffffffL);',
            '',
            block.call('bignum')
          ]
        end

        def upcast_builtin(type, statement, &block)
          block ||= proc { |_result|
            "return #{_result};"
          }
          block.call("(#{convert_builtin(type)})#{statement}")
        end
        
        def upcast_none(statement)
          "#{statement};"
        end

        def convert_array(type)
          "List<#{typemap[type]}>"
        end

        def convert_bignum
          'Long'
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

        def convert_none
          'void'
        end

        def normalize_type(type)
          [
            type.slice(0...-1).map { |_component|
              _component.downcase
            }, 
            type.last 
          ].flatten.join('.')
        end

        def generate_pod(name, data)
          components = name.split('.')
          namespace = components.slice(0...-1)
          pod = components.last

          filename = File.join(@destination, components) + '.java'
          mkdir_p File.dirname(filename)

          File.open(filename, "w") do |_io|
            _io.puts [
              append_newline_if(namespace.empty? || "package #{namespace.join('.')};"),
              'import java.util.*;',
              '',
              "public class #{pod} {",
              indent(
                "public #{pod}(HashMap data) {",
                indent(
                  '_data = data;'
                ),
                '}',
                '',
                "public String toString() {",
                indent(
                  %Q{return "#{name}: " + _data;}
                ),
                '}',
                '',
                data.map { |_name, _type|
                  type = typemap[_type]
                  upcastor = wsdl.types.fetch(_type)
                  [
                    "public boolean #{java_checker_method(_name)}() {",
                    indent(
                      %Q{return _data.containsKey("#{_name}");}
                    ),
                    '}',
                    '',
                    "public #{type} #{java_getter_method(_name)}() throws ClassCastException, MissingResourceException {",
                    indent(
                      %Q{Object value = _data.get("#{_name}");},
                      '',
                      'if(value == null) {',
                      indent(
                        %Q{throw new MissingResourceException("Parameter '#{_name}' not available", "HashMap", "#{_name}");}
                      ),
                      '}',
                      upcastor.upcast(self, type, %Q{value})
                    ),
                    '}',
                    ''
                  ]
                },
                'private HashMap _data;'
              ),
              '}',
              ''
            ]
          end
          puts filename
        end

        private
        #######

        def java_getter_method(name)
          join_capitalized_but_first 'get', *extract_name_components(name)
        end

        def java_checker_method(name)
          join_capitalized_but_first 'has', *extract_name_components(name)
        end

        def java_method(name)
          join_capitalized_but_first *extract_name_components(name)
        end
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'

  class SK::RPC::Java::BuilderTest < Test::Unit::TestCase
    def test_normalize_lines
      builder = SK::RPC::Java::Builder.new(nil, nil)

      assert_equal '', builder.normalize_lines('
      aaa
        bbb
          ccc
        ddd
      ')
    end
  end
end
