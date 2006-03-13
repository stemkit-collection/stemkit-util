# Copyright (c) 2005, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'sk/errors.rb'

module SK
  class Platform
    # This class performs platform determination by mapping a Ruby platform
    # identifier to a class that implements queries for platform name, os and 
    # architecture. The class also implements platform comparision.
    #
    class UnsupportedError < SK::Error
      def initialize(platform)
        super "Platform #{platform.inspect} not supported"
      end
    end

    class << self
      # Returns an object representing current platform.
      #
      def current
        new
      end

      # Returns a platform class corresponding to a given
      # character string.
      #
      def [] (platform)
        new platform
      end

      private
      #######

      def lookup(platform)
	platform = platform.to_s.strip.downcase
	@supported.each do |_ids, _platforms|
	  name, os, arch = Array(_ids).map { |_item| 
            _item.to_s # to accept symbols
          }
	  return [ name, os, arch ] if [ name, *_platforms ].include? platform
	end
	raise UnsupportedError, platform
      end

      private :new
    end

    attr_reader :name, :os, :arch

    # Performs platform comparision. Can compare to another platform
    # istance or to a string.
    #
    def ==(platform)
      begin
        @name == self.class.send(:lookup, platform).first
      rescue UnsupportedError
        false
      end 
    end

    # Returns a platform name when converting to a string.
    #
    def to_s
      name
    end

    private
    #######

    def initialize(*args)
      @name, @os, @arch = self.class.send(:lookup, (args.first or PLATFORM))
    end

    @supported = Hash[
      [ 'sol-x86', :solaris, :x86 ]  => %w{ i386-solaris2.8 },
      [ 'sol-sparc', :solaris ] => %w{ sparc-solaris2.6 sparc-solaris2.9 },
      [ 'sol8-sparc', :solaris ] => %w{ sparc-solaris2.8 },
      [ 'lin-x86', :linux, :x86 ] => %w{ i686-linux i386-linux-gnu },
      [ 'aix5-ppc', :aix5, :ppc ] => %w{ powerpc-aix5.1.0.0 },
      [ 'tiger-ppc', :darwin, :ppc ] => %w{ powerpc-darwin8.1.0 },
      [ 'tru64', :osf5, :alpha ] => %w{ alphaev67-osf5.1b },
      [ 'hpux', :hpux, :risc ] => %w{ hppa2.0w-hpux11.00 }
    ]
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'

  module SK
    class PlatformTest < Test::Unit::TestCase
      def test_current_equals_self
        name = Platform.current.name
        assert_equal Platform.current, Platform[name]
      end

      def test_known_platforms
        assert_equal 'lin-x86', Platform['i386-linux-gnu'].name
        assert_equal 'sol-sparc', "#{Platform['sparc-solaris2.6']}"
        assert_equal true, Platform['powerpc-darwin8.1.0'] == 'tiger-ppc'
        assert_equal false, Platform['sol-sparc'] == Platform['sol-x86']
        assert_equal Platform['lin-x86'].arch, Platform['sol-x86'].arch
        assert_equal Platform['sol-sparc'].os, Platform['sol-x86'].os
        assert_equal false, Platform['lin-x86'].os == Platform['sol-x86'].os
      end

      def test_unsupported
        assert_raises(SK::Platform::UnsupportedError) do
          Platform['___']
        end
      end

      def setup
      end
      
      def teardown
      end
    end
  end
end
