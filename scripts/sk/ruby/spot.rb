=begin
  vim: sw=2:
  Copyright (c) 2013, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Bystritsky, Gennady
=end

module SK
  module Ruby
    class Spot
      class << self
        def [](*args)
          new *args
        end
      end

      attr_reader :object, :file, :line, :method_name

      def initialize(binding)
        with_spot_descriptors binding do |_object, _method, _file, _line|
          @object = _object
          @method_name = _method.to_s
          @file = _file
          @line = _line
        end
      end

      def namespace
        @namespace ||= (instance? ? @object.class : @object)
      end

      def full_method_name
        @full_method_name ||= begin
          case
            when instance?
              [ @object.class.name, @method_name ].join('#')

            when class?
              [ @object.name, @method_name ].join('.')

            else
              [ @object.name, @method_name ].join('::')
          end
        end
      end

      def instance?
        not Module === @object
      end

      def module?
        Module === @object ? (Class === @object ? false : true) : false
      end

      def class?
        Class === @object
      end

      def to_s
        [ full_method_name, line ].join('@')
      end

      private
      #######

      def with_spot_descriptors(binding)
        yield eval('[ self, __method__, __FILE__, __LINE__ ]', binding)
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Ruby
      class << self
        def sample_module_method
          SK::Ruby::Spot[binding]
        end
      end

      class SpotTest < Test::Unit::TestCase
        class << self
          def sample_class_method
            SK::Ruby::Spot[binding]
          end
        end

        def test_instance_spot
          SK::Ruby::Spot[binding].tap do |_spot|
            unless RUBY_VERSION == '1.9.1'
              assert_equal __FILE__, _spot.file
              assert_equal (__LINE__ - 3), _spot.line
            end

            assert_equal false, _spot.class?
            assert_equal false, _spot.module?
            assert_equal true, _spot.instance?

            assert_equal 'test_instance_spot', _spot.method_name
            assert_equal 'SK::Ruby::SpotTest#test_instance_spot', _spot.full_method_name
            assert_equal "SK::Ruby::SpotTest#test_instance_spot@#{_spot.line}", "#{_spot}"
          end
        end

        def test_class_spot
          self.class.sample_class_method.tap do |_spot|
            unless RUBY_VERSION == '1.9.1'
              assert_equal __FILE__, _spot.file
            end

            assert_equal true, _spot.class?
            assert_equal false, _spot.module?
            assert_equal false, _spot.instance?

            assert_equal 'sample_class_method', _spot.method_name
            assert_equal 'SK::Ruby::SpotTest.sample_class_method', _spot.full_method_name
            assert_equal "SK::Ruby::SpotTest.sample_class_method@#{_spot.line}", _spot.to_s
          end
        end

        def test_module_spot
          SK::Ruby.sample_module_method.tap do |_spot|
            unless RUBY_VERSION == '1.9.1'
              assert_equal __FILE__, _spot.file
            end

            assert_equal false, _spot.class?
            assert_equal true, _spot.module?
            assert_equal false, _spot.instance?

            assert_equal 'sample_module_method', _spot.method_name
            assert_equal 'SK::Ruby::sample_module_method', _spot.full_method_name
            assert_equal "SK::Ruby::sample_module_method@#{_spot.line}", _spot.to_s
          end
        end

        def setup
        end
      end
    end
  end
end
