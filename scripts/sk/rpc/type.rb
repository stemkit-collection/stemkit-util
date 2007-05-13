=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

module SK
  module RPC
    class Type
      attr_reader :item

      def initialize(item)
        @item = item
      end
    end
  end
end

