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
        patterns.empty? or patterns.any? { |_pattern|
          File.fnmatch(_pattern, _file)
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
      def test_basics
        locator = FileLocator.new('.')

        locator.expects(:entries).with('.').returns [ 'aaa', 'd1' ]
        locator.expects(:entries).with('d1').returns [ 'd1/bbb', 'd1/ccc' ]
        File.expects(:directory?).with('d1').returns true
        File.expects(:directory?).with('d1/bbb').returns false
        File.expects(:directory?).with('d1/ccc').returns false
        File.expects(:directory?).with('aaa').returns false

        assert_equal [ 'd1/bbb', 'd1/ccc', 'aaa' ], locator.find_bottom_up
      end

      def setup
        super
      end
      
      def teardown
        super
      end
    end
  end
end
