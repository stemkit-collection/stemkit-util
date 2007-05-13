=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'xmlsimple'
require 'sk/rpc/data.rb'
require 'sk/rpc/array.rb'

require 'enumerator'

module SK
  module RPC
    class Wsdl
      attr_reader :data

      def initialize(input)
        @data = parser.xml_in input
      end

      def service
        data.fetch('name')
      end

      def endpoint
        @endpoint ||= data[:service][:port][:address]['location']
      end

      def actions
        @actions ||= begin
          data.fetch(:message).enum_slice(2).inject({}) { |_hash, _info|
            name = _info.first.fetch('name')
            response_part = _info.last.fetch(:part)
            raise "No return type for #{name}" unless response_part['name'] == 'return'

            _hash.update name => {
              :input => [ _info.first.fetch(:part) ].flatten.map { |_item|
                [ _item.fetch('name'), normalize_type(_item.fetch('type')) ]
              },
              :output => normalize_type(response_part.fetch('type'))
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
                  SK::RPC::Data.new members.inject({}) { |_hash, _member|
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
          }.inject { |_hash, _item| _hash.update _item }
        end
      end

      private
      #######

      def normalize_type(type)
        case type
          when %r{^xsd:(.*)$} 
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

