# Copyright (c) 2005, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

module SK
  # A helper class for SK::Application. Implements option storage.
  #
  class OptionRegistry
    attr_reader :entries

    def initialize
      @entries = []
      @factory = Struct.new(:option, :description, :argument, :aliases)
    end

    def add(option, description, argument = nil, *aliases)
      option = '--' + ensure_not_empty(remove_leading_dashes(option))
      aliases = aliases.map { |_alias|
        '-' + ensure_not_empty(remove_leading_dashes(_alias))
      }
      @entries.each do |_entry|
        common = [ _entry.option, *_entry.aliases ] & [ option, *aliases ]
        raise "Multiple options/aliases #{common.inspect}" unless common.empty?
      end
      @entries.push @factory.new(option, description, argument, aliases)
    end

    def add_bulk(*args)
      return if args.empty?
      return add(*args) unless Array === args.first

      args.each do |_entry|
        add_bulk(*_entry) 
      end
    end

    def format_entries
      [
        @entries.map { |_entry|
          [ _entry.to_a ].map { |_option, _description, _argument, _aliases|
            aliases = (_aliases + ['']).join(', ')
            option = [ _option, (_argument && "<#{_argument.strip}>") ].compact.join(' ')

            [ aliases, aliases.size, option, option.size, _description ]
          }.first
        }.transpose
      ].map { |_a|
        [ pad(_a[0], _a[1].max), pad(_a[2], _a[3].max, '-'), _a[4] ]
      }.first.transpose
    end

    private
    #######
    def pad(entries, size, align = '')
      entries.map { |_entry|
        "%#{align}#{size}.#{size}s" % _entry
      }
    end

    def ensure_not_empty(option)
      raise 'Empty option/alias encountered' if option.empty?
      option
    end

    def remove_leading_dashes(option)
      option.scan(%r{^[-\s]*(.*?)\s*$}).first.first
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'

  module SK
    class OptionRegistryTest < Test::Unit::TestCase
      def test_add
        @registry.add('aaa', 'AAA', nil, 'a', 'A')
        assert_equal 1, @registry.entries.size
        assert_equal 2, @registry.entries.first.aliases.size

        @registry.add('bbb', 'BBB')
        assert_equal 2, @registry.entries.size
        assert_equal 0, @registry.entries.slice(1).aliases.size

        assert_raises(RuntimeError) {
          @registry.add('bbb', 'CCC', nil, 'c', 'C')
        }
        assert_equal 2, @registry.entries.size

        assert_raises(RuntimeError) {
          @registry.add('ccc', 'CCC', nil, 'c', 'A')
        }
        assert_equal 2, @registry.entries.size

        @registry.add('ccc', 'CCC', nil, 'c', 'C')
        assert_equal 3, @registry.entries.size
      end

      def test_add_bulk
        @registry.add_bulk [
          [ 'aaa', 'AAA' ],
          [ '--bbb', 'BBB' ],
          [ [ [ '-ccc', 'CCC' ] ] ]
        ]
        assert_equal 3, @registry.entries.size
        assert_equal '--aaa', @registry.entries.slice(0).option
        assert_equal '--bbb', @registry.entries.slice(1).option
        assert_equal '--ccc', @registry.entries.slice(2).option

        @registry.add_bulk '   ddd     ', 'DDD', nil, 'd', 'D'
        assert_equal 4, @registry.entries.size
        assert_equal '--ddd', @registry.entries.slice(3).option

        @registry.add_bulk [ 'zzz', 'DDD', nil ]
        assert_equal 5, @registry.entries.size
      end

      def test_format_entries
        @registry.add 'test', 'Test', 'thing', '-t'
        @registry.add 'install', 'Install', nil, '-i', '-s'

        assert_equal [
          [ '    -t, ', '--test <thing>', 'Test' ],
          [ '-i, -s, ', '--install     ', 'Install' ]
        ], @registry.format_entries
      end

      def setup
        @registry = OptionRegistry.new
      end

      def teardown
        @registry = nil
      end
    end
  end
end
