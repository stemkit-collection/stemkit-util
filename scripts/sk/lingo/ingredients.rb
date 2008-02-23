=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

module SK
  module Lingo
    module Ingredients
      def copyright_holders
        holders = Array(hash['copyright_holders'])
        holders.push user.gecos if holders.empty?

        lines holders
      end

      def authors
        authors = Array(hash['authors'])
        authors.push user.gecos if authors.empty?

        lines authors
      end

      def license
        lines hash['license']
      end
    end
  end
end
