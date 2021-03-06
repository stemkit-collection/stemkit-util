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
    class Substitutor
      def initialize(*args)
        @scope = Scope.new(*args)
      end

      def process(content)
        content.gsub(%r{#\{[^\}]*\}}) { |_match|
          begin
            @scope.instance_eval _match.slice(2...-1)
          rescue Exception => error
            raise TSC::Error, [ "Substituion of #{_match} failed", error ]
          end
        }
      end
    end

    class Scope
      def initialize(item, baker)
        @item, @baker = item, baker
      end

      def full_class_name
        @baker.make_qualified_name @item.namespace, @item.name
      end

      def class_name
        @baker.make_qualified_name @item.name
      end

      def class_reference(*args)
        @baker.make_item_reference @item, *args
      end

      def namespace
        @baker.make_qualified_name @item.namespace
      end

      def indent
        @baker.config.indent
      end

      def class_tag
        @baker.make_item_tag @item
      end
    end
  end
end


if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module Sk
    module Lingo
      class SubstitutorTest < Test::Unit::TestCase
        def test_nothing
        end

        def setup
        end
      end
    end
  end
end
