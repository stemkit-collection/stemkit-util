=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'tsc/string-utils.rb'
require 'tsc/line-builder.rb'

module SK
  module RPC
    class Builder
      include TSC::StringUtils
      include TSC::LineBuilder

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

      def extract_name_components(name)
        name.split(%r{[_-]}).map { |_partial|
          _partial.split(%r{(?=[A-Z])}).map { |_item|
            _item.downcase
          }
        }.flatten
      end
    end
  end
end
