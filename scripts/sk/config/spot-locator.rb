# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'tsc/errors.rb'
require 'sk/config/locator.rb'

module SK
  module Config
    class SpotLocator < Locator
      def initialize(*args)
        super

        if block_given?
          options.update Hash[ yield(options[:item], spot, options[:locator]) ]
        end
      end

      def invoke(processor)
        super

        begin
          processor.process content(self.class.expand_path(item, spot)).join, spot
        rescue Errno::ENOENT
          raise if options[:required]
        end
      end

      def spot
        @spot ||= self.class.expand_path(options[:spot] || '.')
      end

      def item
        options[:item] || locator.item
      end

      private
      #######

      def content(path)
        self.class.open path do |_io|
          return TSC::Error.wrap_with(path) {
            counter = 0
            _io.readlines.map { |_line|
              counter += 1
              tabindex = _line.index("\t")

              raise "Tab char at #{counter}/#{tabindex.next}" if tabindex

              result = _line.scan(%r{^(\s*)@<\s*([^>]+?)\s*>\s*$}).flatten
              result.size != 2 ? _line : content(self.class.expand_path(result.last, File.dirname(path))).map { |_line|
                result.first + _line
              }
            }.flatten
          }
        end
      end

      class << self
        def expand_path(*args)
          File.expand_path(*args)
        end

        def open(*args, &block)
          File.open(*args, &block)
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
      class SpotLocatorTest < Test::Unit::TestCase
        attr_reader :processor

        def test_standalone_no_item_default_spot
          locator = SpotLocator.new
          SpotLocator.expects(:expand_path).with('.').returns('/a/b/c')
          processor.expects(:process).never

          assert_raises RuntimeError do
            locator.item
          end
          assert_equal '/a/b/c', locator.spot
        end

        def test_cascading_with_tailing_item
          locator = SpotLocator.new :locator => SpotLocator.new(:item => 'zzz')
          processor.expects(:process).never

          assert_equal 'zzz', locator.item
        end

        def test_cascading_invoke
          locator = SpotLocator.new :locator => SpotLocator.new(:item => 'zzz', :spot => '/tmp')
          SpotLocator.expects(:expand_path).with('.').returns('/a/b')
          SpotLocator.expects(:expand_path).with('/tmp').returns('/tmp')
          SpotLocator.expects(:open).with('/a/b/zzz').yields StringIO.new('aaa')
          SpotLocator.expects(:open).with('/tmp/zzz').yields StringIO.new('bbb')
          SpotLocator.expects(:expand_path).with('zzz', '/tmp').returns('/tmp/zzz')
          SpotLocator.expects(:expand_path).with('zzz', '/a/b').returns('/a/b/zzz')

          processor.expects(:process).with('aaa', '/a/b')
          processor.expects(:process).with('bbb', '/tmp')

          locator.invoke(processor)
        end

        def setup
          @processor = mock('processor')
        end
      end
    end
  end
end
