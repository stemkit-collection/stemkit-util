# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

require 'tsc/errors.rb'
require 'tsc/dataset.rb'

module SK
  module Config
    class Data
      class MissingPathError < TSC::Error
        def initialize(path)
          super path, "Path missing"
        end
      end

      class << self
        def [](*args)
          self.new(*args)
        end
      end

      include Enumerable

      def initialize(*args)
        @hash = {}

        args.flatten.compact.each do |_item|
          self.class.merge self, _item
        end
      end

      def clone
        self.class.new @hash.clone
      end

      def each(&block)
        @hash.each(&block)
      end

      def each_pair(&block)
        @hash.each_pair(&block)
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

      def fetch(path, fallback = self)
        begin
          locate(path, false) { |_key, _data|
            return _data.to_hash.fetch(_key)
          }
        rescue
          raise MissingPathError, path if fallback.object_id == self.object_id
          fallback
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

      def update(item, options = {})
        self.class.merge(self, item, options)
      end

      class << self
        def merge(receiver, item, options = {})
          control = TSC::Dataset[ :override => true, :consolidate => true ]
          control.update(options)

          loop do
            case receiver
              when Hash
                receiver = self.new receiver
                next

              when self
                case item
                  when Hash, self
                    item.each_pair do |_key, _value|
                      receiver[_key] = merge(receiver[_key], _value, options)
                    end
                    return receiver

                  when Array
                    return merge(receiver, consolidate_array(item), options)

                  else
                    return merge(receiver, { item => self.new }, options) unless receiver.key?(item)
                end

              when Array
                case item
                  when Hash, self, Array
                    return item unless control.consolidate
                    data = consolidate_array(item)

                    return receiver.map { |_item|
                      next _item unless data.key?(_item)
                      self.new(_item => data[_item])
                    }
                end
            end

            break
          end

          control.override == true || receiver.nil? ? item : receiver
        end

        def consolidate_array(item)
          return self.new(item) unless Array === item

          self.new *item.select { |_item|
            case _item
              when Hash, self
                true
              else
                false
            end
          }
        end

        def mesh_array(item)
          return self.new(item) unless Array === item

          item.map { |_item|
            case _item
              when Hash, self
                _item
              else
                Hash[ _item => Hash[] ]
            end
          }.inject(self.new) { |_result, _entry|
            _result.update(_entry)
          }
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

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

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

        def test_fetch
          hash['aaa'] = 'bbb'

          assert_equal 'bbb', hash.fetch('aaa')
          assert_raises Config::Data::MissingPathError do
            hash.fetch('bbb')
          end

          assert_equal 'ccc', hash.fetch('bbb', 'ccc')
          assert_equal nil, hash.fetch('bbb', nil)
        end

        def test_create_with_mixed_types
          hash = SK::Config::Data.new 'aaa', { 'bbb' => 'ccc', 1 => 2 }, 'bbb'
          assert_equal 3, hash.size
          assert_equal true, hash['aaa'].empty?
          assert_equal 2, hash['1']
          assert_equal 'ccc', hash['bbb']
        end

        def test_update_simple_type_with_hash
          hash['a'] = 'zzz'
          assert_equal 'zzz', hash['a']

          hash.update 'a' => Hash[ :zzz => 'bbb' ]
          assert_equal Hash[ 'zzz' => 'bbb' ],  hash[:a]
        end

        def test_update_array_type_with_hash
          hash['a'] = [ 'z', 'b', 'u' ]
          assert_equal [ 'z', 'b', 'u' ], hash['a']

          hash.update 'a' => Data[ :z => 'bbb', :u => 'ccc' ]
          assert_equal [ Hash[ 'z' => 'bbb' ], 'b', Hash[ 'u' => 'ccc' ] ],  hash[:a]
        end

        def test_deep_update
          d1 = Data[
            :system => {
              :s1 => [ :h1, :h2 ],
              :s2 => [ :h1 ]
            }
          ]

          d2 = Data[
            :system => [ :s4, :s1 ]
          ]
          d2.update(d1)

          assert_equal [ :s4, Hash[ "s1" => [ :h1, :h2 ] ] ], d2[:system]
        end

        def test_deep_update_with_arrays
          d1 = Data[
            :system => [
              { :s1 => [ :h1, :h2 ] },
              { :s2 => [ :h1 ] }
            ]
          ]

          d2 = Data[
            :system => [ :s4, :s1 ]
          ]
          d2.update(d1)

          assert_equal [ :s4, Hash[ "s1" => [ :h1, :h2 ] ] ], d2[:system]
        end

        def test_mesh_array
          a = Data.mesh_array [ 1, 2, 3 ]
          assert_equal Hash[ "1"=>{}, "2"=>{}, "3"=>{} ], a
        end

        def test_mesh_array_with_hash_inside
          a = Data.mesh_array [ 1, 2, Hash[ 7=>8 ], 3 ]
          assert_equal Hash[ "7"=>8, "1"=>{}, "2"=>{}, "3"=>{} ], a
        end

        def test_mesh_array_with_hash_inside_override
          a = Data.mesh_array [ 1, 2, Hash[ 7=>8, 1 => { :a => { :b => :c } }, 3 => { 9 => "uu" } ], 3 ]
          assert_equal Hash[ "7"=>8, "1"=>{ "a" => { "b" => :c } }, "2"=>{}, "3" => { "9" => "uu" } ], a
        end

        def test_fetch_on_meshed
          a = Data.mesh_array [ 1, 2, Hash[ 7=>8, 1 => { :a => { :b => :c } }, 3 => { 9 => "uu" } ], 3 ]
          assert_equal :c, a.fetch("1/a/b")
        end

        def setup
          @hash = SK::Config::Data.new
        end
      end
    end
  end
end
