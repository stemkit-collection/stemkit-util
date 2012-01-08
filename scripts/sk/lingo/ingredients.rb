# vim: set sw=2:
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
        holders = Array(data['copyright_holders'])
        holders.push user.description if holders.empty?

        lines holders
      end

      def authors
        authors = Array(data['authors'])
        authors.push user.description if authors.empty?

        lines authors
      end

      def license
        lines data[:license]
      end

      def indent
        @indent ||= (options.indent || tag[:indent] || data[:indent]).to_i
      end

      def shebang
        lines(target[:shebang] || tag[:shebang] || data[:shebang])
      end

      def vim
        lines(target[:vim] || tag[:vim] || data[:vim])
      end
    end
  end
end
