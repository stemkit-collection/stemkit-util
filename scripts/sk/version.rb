=begin
  vim: sw=2:
  Copyright (c) 2013, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Bystritsky, Gennady (bystr@mac.com)
=end

require 'tsc/errors'
require 'tsc/dataset'
require 'forwardable'

module SK
  # This class encapsulates version specification including optional ABI. For
  # the time being it doesn't split the version portion to its components
  # (major, minor, patch, build, etc.) which may be added later.
  #
  class Version
    COMPONENTS = [ :spec, :version, :major, :minor, :patch, :build, :label, :abi ]

    class FormatError < TSC::Error
      attr_reader :spec

      def initialize(spec)
        @spec = spec
        super 'Wrong version', spec.to_s.inspect.slice(1...-1)
      end
    end

    class << self
      include Forwardable

      # @param [String, SK::Version] spec
      #   Another version instance or a version specification string.
      #   Currently supported format for a version string is:
      #     <major>[.<minor>[.<build>]][-|.b<build>][[-|_]<label>][:<abi>]
      #
      # @return [SK::Version]
      #   A version instance corresponding to input specification.
      #
      def make(spec)
        case spec
          when String
            new TSC::Dataset.new components normalize(spec, parse(spec).flatten)

          when SK::Version
            spec

          else
            raise FormatError, spec
        end
      end

      private
      #######

      def components(defaults)
        Hash[ [ COMPONENTS, defaults ].transpose ]
      end

      def parse(spec)
        spec.scan %r{^((\d+)(?:[.](\d+)(?:[.](\d+)(?:[.](\d+))?)?)?(?:[.-]b(\d+))?(?:[-_]?(\w+))?)(?:[:](\w+))?$}
      end

      def normalize(spec, c)
        raise FormatError, spec unless c.size == 8
        [ spec, c[0], c[1].to_i, c[2].to_i, c[3].to_i, (c[5] || c[4]).to_i, c[6], c[7] ]
      end

      private :new
    end

    def_delegators :components, *COMPONENTS

    # @return [TSC::Dataset]
    #   A dataset with version components.
    #
    attr_reader :components

    def initialize(components)
      @components = components
    end

    def to_s
      spec
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    class VersionTest < Test::Unit::TestCase
      def test_make_with_good_spec_succeeds
        SK::Version.make('5.3').tap do |_version|
          assert_equal 5, _version.major
          assert_equal 3, _version.minor
          assert_equal 0, _version.patch
          assert_equal 0, _version.build
          assert_equal nil, _version.label
          assert_equal nil, _version.abi
        end

        SK::Version.make('5.3-b78s:64').tap do |_version|
          assert_equal 5, _version.major
          assert_equal 3, _version.minor
          assert_equal 0, _version.patch
          assert_equal 78, _version.build
          assert_equal 's', _version.label
          assert_equal '64', _version.abi

          assert_equal '5.3-b78s', _version.version
          assert_equal '5.3-b78s:64', _version.spec
          assert_equal '5.3-b78s:64', _version.to_s
        end

        SK::Version.make('5.3.4.5.b78_zzz').tap do |_version|
          assert_equal 5, _version.major
          assert_equal 3, _version.minor
          assert_equal 4, _version.patch
          assert_equal 78, _version.build
          assert_equal 'zzz', _version.label
          assert_equal nil, _version.abi
        end
      end

      def test_make_with_bad_spec_fails
        error = assert_raises SK::Version::FormatError do
          SK::Version.make('zzz')
        end
        assert_equal 'zzz', error.spec
      end

      def test_make_with_another_instance_returns_same_object
        SK::Version.make('1.2.3').tap do |_version|
          assert_equal _version.object_id, SK::Version.make(_version).object_id
        end
      end

      def setup
      end
    end
  end
end
