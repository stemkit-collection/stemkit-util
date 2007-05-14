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
            append_newline_if(namespace.empty? && "package #{namespace.join('.')};"),
            "public class #{wsdl.service} {",
            indent(
              "#{wsdl.service}() {",
              '}',
              '',
              "#{wsdl.service}(String endpoint) {",
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
              "#{_info[:output]} #{_name}() {",
              '}'
            ]
          }
        end
      end
    end
  end
end
