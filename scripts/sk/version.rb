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

      # @param [String] spec
      #   A version specification string. Currently supported format is
      #   <major>[.<minor>[.<build>]][-|.b<build>][[-|_]<label>][:<abi>]
      #
      # @return [SK::Version]
      #   A version instance corresponding to input specification.
      #
      def make(spec)
        new components normalize(spec, parse(spec.to_s).flatten)
      end

      def components(defaults = [ nil ] * COMPONENTS.size)
        Hash[ [ COMPONENTS, defaults ].transpose ]
      end

      private
      #######

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

    def initialize(params = {})
      @components = TSC::Dataset[self.class.components].update params
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    class VersionTest < Test::Unit::TestCase
      def test_partial_instance
        SK::Version.send(:new, :major => 5, :minor => 3).tap do |_version|
          assert_equal 5, _version.major
          assert_equal 3, _version.minor
          assert_equal nil, _version.patch
          assert_equal nil, _version.build
          assert_equal nil, _version.label
          assert_equal nil, _version.abi
        end
      end

      def test_good_make
        SK::Version.make('5.3').tap do |_version|
          assert_equal 5, _version.major
          assert_equal 3, _version.minor
          assert_equal 0, _version.patch
          assert_equal 0, _version.build
          assert_equal nil, _version.label
          assert_equal nil, _version.abi
        end

        SK::Version.make('5.3-b78s:64').tap do |_version|
          assert_equal '5.3-b78s', _version.version
          assert_equal 5, _version.major
          assert_equal 3, _version.minor
          assert_equal 0, _version.patch
          assert_equal 78, _version.build
          assert_equal 's', _version.label
          assert_equal '64', _version.abi
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

      def test_bad_make
        error = assert_raises SK::Version::FormatError do
          SK::Version.make('zzz')
        end
        assert_equal 'zzz', error.spec
      end

      def setup
      end
    end
  end
end
