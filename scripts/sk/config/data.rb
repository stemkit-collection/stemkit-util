# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

require 'tsc/errors.rb'

module SK
  module Config
    class Data
      class MissingPathError < TSC::Error
        def initialize(path)
          super "Path #{path.inspect} missing"
        end
      end

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

      def [](path)
        begin
          locate(path, false) { |_key, _data|
            return _data.to_hash[_key]
          }
        rescue
          nil
        end
      end

      def fetch(path, fallback = nil)
        begin
          locate(path, false) { |_key, _data|
            return _data.to_hash.fetch(_key)
          }
        rescue
          fallback or raise MissingPathError, path
        end
      end

      def []=(path, value)
        locate(path, true) { |_key, _data|
          _data.to_hash[_key] = normalize(value)
        }
      end

      def empty?
        @hash.empty?
      end

      def key?(path)
        begin
          locate(path, false) { |_key, _data|
            _data.to_hash.key?(_key)
          }
        rescue
          false
        end
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

      def locate(path, create, &block)
        keys = normalize_key_path(path)
        key = keys.pop

        yield key, keys.inject(self) { |_data, _key|
          raise "Not #{self.class.name.inspect}" unless self.class === _data
          if _data.to_hash.key?(_key) == false 
            raise MissingPathError, keys.join('/') unless create
            _data.to_hash[_key] = self.class.new
          end

          _data.to_hash[_key]
        }
      end

      def normalize_key_path(path)
        path.to_s.split('/').map { |_item|
          item = _item.strip
          item unless item.empty?
        }.compact
      end

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

        def test_path
          assert_equal false, hash.key?("a/b/c")
          assert_equal true, hash.empty?

          hash['a/b/c'] = "zzz"
          assert_equal true, hash.key?("a/b/c")
          assert_equal "zzz", hash["a/b/c"]
          assert_equal 1, hash.size
          assert_equal 1, hash[:a].size
          assert_equal Hash[ "c" => "zzz" ], hash["a/b"]
        end

        def setup
          @hash = SK::Config::Data.new
        end
      end
    end
  end
end
