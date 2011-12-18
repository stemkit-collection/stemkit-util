=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'tsc/application.rb'
require 'sk/config/uproot-path-collector.rb'
require 'tsc/path.rb'
require 'tsc/errors.rb'

module SK
  class ScopeError < TSC::Error
  end

  class SelectableScopeError < SK::ScopeError
    def initialize(args)
      label, selectors = *args
      super "#{label.capitalize} scope top not found (#{reason(selectors)})"
    end

    def reason(selectors)
      [ 'no', selector_label(selectors), selector_list(selectors) ].compact.join(' ')
    end

    def selector_label(selectors)
      "selector#{'s' unless selectors.size == 1}"
    end

    def selector_list(selectors)
      selectors.join(', ') unless selectors.empty?
    end
  end

  class SourceScopeError < SK::ScopeError
    def initialize(top)
      super "Scope top not under src (#{top})"
    end
  end

  class ScopingLauncher < TSC::Application
    def start
      handle_errors {
        require 'rubygems'
        require 'pathname'

        setup
      }
    end

    def local_scope_top
      @local_scope_top ||= Pathname.new figure_scope_top('local', '.', local_scope_selectors)
    end

    def global_scope_top
      @global_scope_top ||= Pathname.new figure_scope_top('global', script_location, global_scope_selectors)
    end

    def root
      @root ||= begin
        local_scope_top.split.tap { |_root, _component|
          break _root if _component.to_s == 'src'
          raise 'Not under src'
        }
      end
    end

    def srctop
      root.join 'src'
    end

    def bintop
      root.join  'bin'
    end

    def gentop
      root.join  'gen'
    end

    def pkgtop
      root.join  'pkg'
    end

    protected
    #########

    def setup
      raise TSC::NotImplementedError, :setup
    end

    def local_scope_selectors
    end

    def global_scope_selectors
    end

    private
    #######

    def figure_scope_top(label, origin, selectors)
      with_selectors selectors do |_selectors|
        _selectors.each do |_selector|
          SK::Config::UprootPathCollector.new(:item => _selector, :spot => origin).locations.tap { |_locations|
            return _locations.last unless _locations.empty?
          }
        end
        raise SK::SelectableScopeError, [ label, _selectors ]
      end
    end

    def with_selectors(selectors)
      yield Array(selectors).flatten.compact
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    class ScopingLauncherTest < Test::Unit::TestCase
      def test_exits_if_not_subclassed
        SK::ScopingLauncher.any_instance.expects(:print_error).with instance_of(TSC::NotImplementedError)
        assert_raises SystemExit do
          SK::ScopingLauncher.new.start
        end
      end

      def test_fails_if_no_scope_selectors
        SK::ScopingLauncher.new.tap { |_app|
          error = assert_raises SK::SelectableScopeError do
            _app.local_scope_top
          end

          assert_equal 'Local scope top not found (no selectors)', error.message
        }
      end

      def test_fails_if_single_scope_selector_not_found
        SK::ScopingLauncher.any_instance.expects(:local_scope_selectors).returns 'aaa/bbb/ccc'

        SK::ScopingLauncher.new.tap { |_app|
          error = assert_raises SK::SelectableScopeError do
            _app.local_scope_top
          end

          assert_equal 'Local scope top not found (no selector aaa/bbb/ccc)', error.message
        }
      end

      def test_fails_if_multiple_scope_selectors_not_found
        SK::ScopingLauncher.any_instance.expects(:local_scope_selectors).returns [ 
          'aaa/bbb/ccc',
          'zzz/uuu/bbb'
        ]

        SK::ScopingLauncher.new.tap { |_app|
          error = assert_raises SK::SelectableScopeError do
            _app.local_scope_top
          end

          assert_equal 'Local scope top not found (no selectors aaa/bbb/ccc, zzz/uuu/bbb)', error.message
        }
      end

      def setup
      end
    end
  end
end
