=begin
  vim: set sw=2:
  Copyright (c) 2009, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

module SK
  class Numeral
    ROMAN_SHORTENED = [
      [1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]
    ]

    ROMAN_CLASSIC = [
      [1000, "M"], [500, "D"], [100, "C"], [50, "L"], [10, "X"], [5, "V"], [1, "I"]
    ]
    class << self
      def to_roman(number, shortened = true)
        return 'N' if number.zero?

        raise RangeError, "Must be within 0-3999" if number < 0 || number > 3999

        (shortened == true ? ROMAN_SHORTENED : ROMAN_CLASSIC).inject(["", number]) { |(result, number), (order,  roman)|
          [ result + roman * (number / order), number % order ]
        }.first
      end
    end
  end
end

if $0 == __FILE__ 
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  module SK
    class NumeralTest < Test::Unit::TestCase
      def test_to_roman_range
        assert_raises(RangeError) {
          SK::Numeral.to_roman(-1)
        }
        assert_equal "N", SK::Numeral.to_roman(0)
        assert_equal "N", SK::Numeral.to_roman(0, false)
        assert_equal "MMMCMXCIX", SK::Numeral.to_roman(3999)
        assert_equal "MMMDCCCCLXXXXVIIII", SK::Numeral.to_roman(3999, false)

        assert_raises(RangeError) {
          SK::Numeral.to_roman(4000)
        }
      end

      def test_to_roman_classic
        assert_equal "I", SK::Numeral.to_roman(1, false)   
        assert_equal "IIII", SK::Numeral.to_roman(4, false)   
        assert_equal "V", SK::Numeral.to_roman(5, false)   
        assert_equal "VI", SK::Numeral.to_roman(6, false)   
        assert_equal "VIIII", SK::Numeral.to_roman(9, false)   
        assert_equal "X", SK::Numeral.to_roman(10, false)  
        assert_equal "XVIIII", SK::Numeral.to_roman(19, false)  
        assert_equal "XXI", SK::Numeral.to_roman(21, false)  
        assert_equal "CLXXX", SK::Numeral.to_roman(180, false) 
        assert_equal "DCCCCXXXXVIIII", SK::Numeral.to_roman(949, false) 
      end

      def test_to_roman_short
        assert_equal "I", SK::Numeral.to_roman(1)   
        assert_equal "IV", SK::Numeral.to_roman(4)   
        assert_equal "V", SK::Numeral.to_roman(5)   
        assert_equal "VI", SK::Numeral.to_roman(6)   
        assert_equal "IX", SK::Numeral.to_roman(9)   
        assert_equal "X", SK::Numeral.to_roman(10)  
        assert_equal "XIX", SK::Numeral.to_roman(19)  
        assert_equal "XXI", SK::Numeral.to_roman(21)  
        assert_equal "CLXXX", SK::Numeral.to_roman(180) 
        assert_equal "CMXLIX", SK::Numeral.to_roman(949) 
      end

      def setup
      end
    end
  end
end

