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
      def source_indent
        @source_indent ||= tag['source-indent'].tap { |_indent|
          return Integer(_indent) if _indent
        }
      end

      def copyright_holders
        @copyright_holders ||= lines normalize_lines(data['copyright_holders']).tap { |_holders|
          _holders.push user.description if _holders.empty?
        }
      end

      def authors
        @authors ||= lines normalize_lines(data['authors']).tap { |_authors|
          _authors.push user.description if _authors.empty?
        }
      end

      def license
        @license ||= lines data[:license]
      end

      def indent
        @indent ||= (options.indent || tag[:indent] || data[:indent]).to_i
      end

      def shebang
        @shebang ||= lines(target[:shebang] || tag[:shebang] || data[:shebang])
      end

      def vim
        @vim ||= lines(target[:vim] || tag[:vim] || data[:vim])
      end
    end
  end
end
