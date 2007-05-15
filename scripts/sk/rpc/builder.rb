=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

module SK
  module RPC
    class Builder
      attr_reader :wsdl, :namespace

      def initialize(wsdl, namespace)
        @wsdl = wsdl
        @namespace = namespace
      end

      def prepend_newline_if(content)
        (!content || content==true || content.empty?) ? [] : [ '', content ]
      end

      def append_newline_if(content)
        (!content || content==true || content.empty?) ? [] : [ content, '' ]
      end

      def indent(*lines)
        lines.flatten.map { |_line|
          '  ' + _line
        }
      end
    end
  end
end
