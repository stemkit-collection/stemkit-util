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

      def typemap
        @typemap ||= Hash.new { |_hash, _key|
          mapped = wsdl.types.fetch(_key).convert(self, _key)
          _hash[_key] = mapped
          _hash[mapped] = mapped
        }
      end

      def convert_pod(name, item)
        normalized = normalize_type(name)
        generate_pod normalized, item

        normalized
      end

      def prepend_newline_if(content)
        (!content || content==true || content.empty?) ? [] : [ '', content ]
      end

      def append_newline_if(content)
        (!content || content==true || content.empty?) ? [] : [ content, '' ]
      end

      def indent(*lines)
        lines.flatten.compact.map { |_line|
          '  ' + _line
        }
      end

      def extract_name_components(name)
        name.split(%r{[_-]}).map { |_partial|
          _partial.split(%r{(?=[A-Z])}).map { |_item| 
            _item.downcase 
          }
        }.flatten
      end

      def join_capitalized_but_first(first, *components)
        [ first, components.map { |_item| _item.capitalize } ].join
      end
    end
  end
end
