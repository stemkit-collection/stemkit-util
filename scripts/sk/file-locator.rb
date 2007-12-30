=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

module SK
  class FileLocator
    def initialize(top)
      @top = top
    end

    def find_bottom_up(*patterns)
      find(@top, patterns).flatten.compact
    end

    protected
    #########

    def find(location, patterns)
      directories, files = entries(location).partition { |_entry|
        File.directory? _entry
      }
      directories.map { |_directory|
        find(_directory, patterns)
      } + files.select { |_file|
        patterns.empty? || patterns.any? { |_pattern|
          File.fnmatch("**/#{_pattern}", _file, File::FNM_DOTMATCH)
        }
      }
    end

    def entries(location)
      Dir[ File.join(location, '*') ]
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    class FileLocatorTest < Test::Unit::TestCase
      attr_reader :locator

      def test_bottom_up_no_params
        assert_equal [ 
          './d1/bbb', './d1/ccc.1', 
          './d2/bbb.1', './d2/ccc.2', 
          './aaa' 
        ], locator.find_bottom_up
      end

      def test_bottom_up_asterisk
        assert_equal [ 
          './d1/bbb', './d1/ccc.1', 
          './d2/bbb.1', './d2/ccc.2', 
          './aaa' 
        ], locator.find_bottom_up('*')
      end

      def test_bottom_up_select_dot_1
        assert_equal [ './d1/ccc.1', './d2/bbb.1' ], locator.find_bottom_up('*.1')
      end

      def test_bottom_up_select_dot_2
        assert_equal [ './d2/ccc.2' ], locator.find_bottom_up('*.2')
      end

      def test_bottom_up_select_none_for_dot_3
        assert_equal [], locator.find_bottom_up('*.3')
      end

      def setup
        @locator = FileLocator.new('.')

        locator.expects(:entries).with('.').returns [ './aaa', './d1', './d2' ]
        locator.expects(:entries).with('./d1').returns [ './d1/bbb', './d1/ccc.1' ]
        locator.expects(:entries).with('./d2').returns [ './d2/bbb.1', './d2/ccc.2' ]

        File.expects(:directory?).with('./d1').returns true
        File.expects(:directory?).with('./d2').returns true

        File.expects(:directory?).with('./d1/bbb').returns false
        File.expects(:directory?).with('./d1/ccc.1').returns false

        File.expects(:directory?).with('./d2/bbb.1').returns false
        File.expects(:directory?).with('./d2/ccc.2').returns false

        File.expects(:directory?).with('./aaa').returns false
      end
    end
  end
end
