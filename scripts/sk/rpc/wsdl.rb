=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'xmlsimple'
require 'sk/rpc/pod.rb'
require 'sk/rpc/array.rb'
require 'sk/rpc/none.rb'
require 'sk/rpc/builtin.rb'

require 'enumerator'

module SK
  module RPC
    class Wsdl
      attr_reader :data

      def initialize(input)
        @data = parser.xml_in input
        @standard_types = { 
          'none' => SK::RPC::None.new 
        }
      end

      def service
        data.fetch(:service).fetch('name')
      end

      def endpoint
        @endpoint ||= data[:service][:port][:address]['location']
      end

      def actions
        @actions ||= begin
          data.fetch(:message).enum_slice(2).inject({}) { |_hash, _info|
            name = _info.first.fetch('name')
            response_part = _info.last[:part]

            raise "No return type for #{name}" if response_part && response_part['name'] != 'return'

            _hash.update name => {
              :input => [ _info.first.fetch(:part) ].flatten.map { |_item|
                [ _item.fetch('name'), normalize_type(_item.fetch('type')) ]
              },
              :output => (response_part ? normalize_type(response_part.fetch('type')) : 'none')
            }
          }
        end
      end

      def types
        @types ||= begin
          data[:types][:complextype].map { |_item|
            members = _item[:all]
            complex = _item[:complexcontent]

            Hash[
              normalize_type('typens:' + _item.fetch('name')) => begin
                if members
                  SK::RPC::Pod.new members.inject({}) { |_hash, _member|
                    _hash.update _member.fetch('name') => normalize_type(_member.fetch('type'))
                  }
                elsif complex
                  base = complex.fetch('base')
                  case base
                    when 'soapenc:Array'
                      SK::RPC::Array.new normalize_type(complex[:attribute]['wsdl:arrayType'].slice(0...-2))
                    else
                      raise "Unsupported complex type #{base.inspect}"
                  end
                else
                  raise "Unknown data type"
                end
              end
            ]
          }.inject(@standard_types.clone) { |_hash, _item| _hash.update _item }
        end
      end

      private
      #######

      def normalize_type(type)
        case type
          when %r{^xsd:(.*)$} 
            @standard_types[$1] = SK::RPC::Builtin.new($1)
            $1
          when %r{^typens:(.*)$}
            $1.split('..')
          else 
            raise "Unknown type #{type.inspect}"
        end
      end

      def parser
        @parser ||= XmlSimple.new Hash[
          'KeyToSymbol' => true, 
          'ForceArray' => false, 
          'GroupTags' => { 
            :all => :element , 
            :complexcontent => :restriction,
            :types => :schema
          }
        ]
      end
    end
  end
end

