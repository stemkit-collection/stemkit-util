=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'xmlsimple'
require 'sk/rpc/data.rb'
require 'sk/rpc/array.rb'

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
        pp data.fetch(:message)
      end

      def types
        pp service
        pp endpoint
        pp actions

        @types ||= begin
          data[:types][:complextype].map { |_item|
            members = _item[:all]
            complex = _item[:complexcontent]

            Hash[
              _item.fetch('name') => begin
                if members
                  SK::RPC::Data.new members.inject({}) { |_hash, _member|
                    _hash.update _member.fetch('name') => _member.fetch('type')
                  }
                elsif complex
                  base = complex.fetch('base')
                  case base
                    when 'soapenc:Array'
                      SK::RPC::Array.new(complex[:attribute]['wsdl:arrayType'].slice(0...-2))
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

