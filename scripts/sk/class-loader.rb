# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

module SK
  class ClassLoader
    class << self
      def [](specification)
        self.new specification
      end
    end

    def initialize(specification)
      @specification = specification
    end

    def require
      super path
      factory
    end

    def load
      super path
      factory
    end

    def path
      @path ||= begin 
        File.join @specification.split('::').map { |_component|
          _component.split(%r{([A-Z][a-z0-9_]+[A-Z][A-Z]+)|([A-Z][A-Z]*[a-z0-9_]+)}).flatten.map { |_part|
            _part.downcase unless _part.strip.empty?
          }.compact.join('-')
        }
      end
    end

    def factory
      @factory ||= begin
        @specification.split('::').inject(Module) { |_module, _component|
          _module.const_get _component
        }
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    class ClassLoaderTest < Test::Unit::TestCase
      def test_figure_factory
        assert_equal String, ClassLoader.new('String').factory
      end

      def test_require 
        assert_equal StringIO, ClassLoader.new('StringIO').require
      end

      def test_figure_path
        assert_equal 'a/b/test-class', ClassLoader.new('A::B::TestClass').path
      end

      def test_figure_path_stringio
        assert_equal "stringio", ClassLoader['StringIO'].path
      end

      def test_figure_path_jruby
        assert_equal "jruby/drb-server", ClassLoader['JRuby::DRbServer'].path
      end
    end
  end
end
