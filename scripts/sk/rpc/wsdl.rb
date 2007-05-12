=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'xmlsimple'

module SK
  module RPC
    class Wsdl
      attr_reader :data

      def initialize(input)
        @data = parser.xml_in input
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

