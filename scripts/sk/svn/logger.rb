=begin
  vim: sw=2:
  Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

module SK
  module Svn
    module Logger
      def verbose?
        @verbose ? true : false
      end

      def verbose=(state)
        @verbose = state ? true : false
      end

      def log(*args, &block)
        return unless verbose?

        $stderr.puts [
          self.class.name.to_s,
          args.map { |_item|
            Symbol === _item.to_s ? _item : _item.inspect
          },
          if block
            begin
              block.call
            rescue => error
              error
            end.inspect
          end
        ].flatten.compact.join(': ')
      end
    end
  end
end
