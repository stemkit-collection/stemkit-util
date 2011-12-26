=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: EMC Gennady Bystritsky
=end

require 'tsc/dataset.rb'

module SK
  module Config
    class DataInterpolator
      def initialize(location, attributes = nil)
        @location, @attributes = location, attributes
      end

      def transform(data)
        case data
          when String
            data.gsub(%r{(%[Rr])|(?:[#][{]\s*(\w+)\s*[}])}) { |_match|
              next @location if $1
              next @attributes.send($2) if @attributes and $2

              _match
            }

          when Array
            data.map { |_item|
              transform _item
            }

          when Hash
            data.update(data) { |_key, _value, _other|
              transform _value
            }
        end
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Config
      class DataInterpolatorTest < Test::Unit::TestCase
        def test_root_transformed_in_strings
          interpolator = SK::Config::DataInterpolator.new '/aaa/bbb/ccc'

          assert_equal 'hohoho', interpolator.transform('hohoho')
          assert_equal '/aaa/bbb/ccc', interpolator.transform('%r')
          assert_equal '--/aaa/bbb/ccc--/aaa/bbb/ccc', interpolator.transform('--%R--%r')
          assert_equal '--/aaa/bbb/ccc--#{uuu}--', interpolator.transform('--%R--#{uuu}--')
        end

        def test_attributes_transformed_in_strings
          attributes = TSC::Dataset.new :fff => 'v1', :abc => 'v2'
          interpolator = SK::Config::DataInterpolator.new '/aaa/bbb/ccc', attributes

          assert_equal 'v1', interpolator.transform('#{fff}')
          assert_equal '--v1--v2--v1--', interpolator.transform('--#{fff}--#{abc}--#{fff}--')
        end

        def test_arrays_transformed
          attributes = TSC::Dataset.new :fff => 'v1', :abc => 'v2'
          interpolator = SK::Config::DataInterpolator.new '/a/b/c', attributes

          assert_equal [ [ '/a/b/c', 'v1' ], '/a/b/c--v1--v2' ], interpolator.transform([ [ '%r', '#{fff}' ], '%r--#{fff}--#{abc}' ])
        end

        def test_hashes_transformed
          attributes = TSC::Dataset.new :fff => 'v1', :abc => 'v2'
          interpolator = SK::Config::DataInterpolator.new '/a/b/c', attributes

          assert_equal Hash[ :aaa => [ '/a/b/c', 'v1' ], :bbb => '/a/b/c--v1--v2' ], interpolator.transform( :aaa => [ '%r', '#{fff}' ], :bbb => '%r--#{fff}--#{abc}' )
        end

        def setup
        end
      end
    end
  end
end
