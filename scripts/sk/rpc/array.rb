=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'sk/rpc/type.rb'

module SK
  module RPC
    class Array < SK::RPC::Type
      def convert(processor, name)
        processor.convert_array(item)
      end

      def upcast(processor, name, statement, &block)
        processor.upcast_array(item, statement, &block)
      end
    end
  end
end

