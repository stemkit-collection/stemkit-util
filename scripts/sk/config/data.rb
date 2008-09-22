# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

module SK
  module Config
    class Data
      class << self
        def [](*args)
          self.new(*args)
        end
      end

      def initialize(*args)
        @hash = {}

        args.each do |_item|
          case _item
            when Hash, self.class
              update _item
          end
        end
      end

      def ==(other)
        other == @hash 
      end

      def to_hash
        @hash
      end

      def [](key)
        @hash[ key.to_s.strip ]
      end

      def []=(key, value)
        @hash[key.to_s.strip] = normalize(value)
      end

      def empty?
        @hash.empty?
      end

      def key?(key)
        @hash.key?(key.to_s.strip)
      end

      def has_key?(key)
        key?(key)
      end

      def size
        @hash.size
      end

      def update(hash)
        hash.each_pair do |_key, _value|
          value = self[_key]
          if self.class === value
            case _value
              when Hash, self.class
                value.update(_value)
                next
            end
          end

          self[_key] = _value
        end
      end

      private
      #######

      def normalize(value)
        case value
          when Array
            value.map { |_item|
              normalize(_item)
            }

          when Hash
            self.class.new(value)

          else
            value
        end
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'

  module SK
    module Config
      class DataTest < Test::Unit::TestCase
        attr_reader :hash

        def test_basics
          assert_equal 0, hash.size
          assert_equal true, hash.empty?
          assert_equal false, hash.key?("abc")
          assert_equal nil, hash["abc"]
        end

        def test_key_types
          hash["aaa"] = "bbb"
          assert_equal 1, hash.size
          assert_equal false, hash.empty?

          assert_equal "bbb", hash["aaa"]
          assert_equal "bbb", hash[:aaa]

          hash[:aaa] = "ccc"
          assert_equal 1, hash.size
          assert_equal "ccc", hash["aaa"]

          hash[5.3] = "uuu"
          assert_equal 2, hash.size
          assert_equal "uuu", hash["5.3"]
          assert_equal "uuu", hash[5.3]
          assert_equal "uuu", hash["  5.3 "]
        end

        def test_update
          hash.update Hash[ 1 => Hash[ 2 => 3, 4 => 5 ] ]
          hash.update Hash[ 1 => Hash[ "2" => 6, 7 => 8 ] ]

          assert_equal 1, hash.size
          assert_equal true, hash.key?(1)
          assert_equal true, hash.key?("1")

          assert_equal 3, hash[1].size
          assert_equal 6, hash[1][2]
          assert_equal 5, hash[1][4]
          assert_equal 8, hash[1]["  7  "]
        end

        def setup
          @hash = SK::Config::Data.new
        end
      end
    end
  end
end
