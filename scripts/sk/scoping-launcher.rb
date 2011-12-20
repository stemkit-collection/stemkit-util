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

  class NotInPathError < TSC::Error
    def initialize(name)
      super "No #{name.inspect} in PATH"
    end
  end

  class ScopingLauncher < TSC::Application
    def start
      handle_errors {
        require 'rubygems'
        require 'pathname'

        setup

        find_in_path(os.exe(script_name)).tap { |_commands|
          _commands.shift while myself?(_commands.first) 
          raise NotInPathError, script_name if _commands.empty?

          invoke _commands.first, command_line_arguments(ARGV)
        }
      }
    end

    def environment
      @environment ||= {}
    end

    def update_environment(env)
      environment.update(env)
    end

    def myself?(path)
      program_file_realpath == Pathname.new(path).realpath if path
    end

    def program_file_realpath
      @program_file_realpath ||= Pathname.new($0).realpath
    end

    def command_line_arguments(args)
      args
    end

    def invoke(*cmdline)
      with_normalized_array cmdline do |_cmdline|
        trace _cmdline.join(' ')
        populate_environment
        Process.exec *_cmdline.map { |_item|
          _item.to_s
        }
      end
    end

    def populate_environment
      return if environment.empty?

      environment.each_pair do |_key, _value|
        setenv [ :sk, script_name, _key ].join('_').upcase, _value.to_s
      end
    end

    def setenv(key, value)
      ENV[key] = value
      trace "#{key} => #{value.inspect}"
    end

    def trace(*args)
      return unless verbose?

      with_normalized_array(args) do |_items|
        _items.each do |_item|
          _item.to_s.lines do |_line|
            $stderr.puts '### ' + _line
          end
        end
      end
    end

    def local_scope_top
      @local_scope_top ||= Pathname.new figure_scope_top('local', '.', local_scope_selectors)
    end

    def local_scope?
      @local_scope ||= begin
        local_scope_top
        true
      rescue SK::ScopeError
        false
      end
    end

    def global_scope_top
      @global_scope_top ||= Pathname.new figure_scope_top('global', script_location, global_scope_selectors)
    end

    def global_scope?
      @global_scope ||= begin
        global_scope_top
        true
      rescue SK::ScopeError
        false
      end
    end

    def root
      @root ||= begin
        local_scope_top.split.tap { |_root, _component|
          break _root if _component.to_s == 'src'
          raise SK::SourceScopeError, local_scope_top
        }
      end
    end

    def source_scope?
      @source_scope ||= begin
        root
        true
      rescue SK::ScopeError, SK::SourceScopeError
        false
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
      with_normalized_array selectors do |_selectors|
        _selectors.each do |_selector|
          SK::Config::UprootPathCollector.new(:item => _selector, :spot => origin).locations.tap { |_locations|
            return _locations.last unless _locations.empty?
          }
        end
        raise SK::SelectableScopeError, [ label, _selectors ]
      end
    end

    def with_normalized_array(array)
      yield Array(array).flatten.compact
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
      
      def test_returns_closest_local_top_if_scope_determined
        SK::ScopingLauncher.any_instance.expects(:local_scope_selectors).returns 'aaa/bbb/ccc'

        top = Pathname.new(Dir.pwd).parent
        path = top.join('aaa').join('bbb').join('ccc').to_s
        upper_path = top.parent.join('aaa').join('bbb').join('ccc').to_s

        Dir.expects('[]').with(anything).at_least_once.returns []
        Dir.expects('[]').with(path).at_least_once.returns path
        Dir.expects('[]').with(upper_path).at_least_once.returns upper_path

        SK::ScopingLauncher.new.tap { |_app|
          assert_equal top, _app.local_scope_top
        }
      end

      def test_root_fails_if_not_under_src
        SK::ScopingLauncher.any_instance.expects(:local_scope_top).at_least_once.returns Pathname.new('/aaa/bbb/ccc')

        SK::ScopingLauncher.new.tap { |_app|
          error = assert_raises SK::SourceScopeError do
            _app.srctop
          end

          assert_equal "Scope top not under src (/aaa/bbb/ccc)", error.message
        }
      end

      def test_not_in_source_scope
        SK::ScopingLauncher.any_instance.expects(:local_scope_top).at_least_once.returns Pathname.new('/aaa/bbb/ccc')

        SK::ScopingLauncher.new.tap { |_app|
          assert _app.source_scope? == false
        }
      end

      def test_queries
        SK::ScopingLauncher.any_instance.expects(:local_scope_top).at_least_once.returns Pathname.new('/aaa/bbb/ccc/src')
        SK::ScopingLauncher.any_instance.expects(:global_scope_top).at_least_once.returns Pathname.new('/zzz')

        SK::ScopingLauncher.new.tap { |_app|
          assert _app.global_scope? == true
          assert _app.source_scope? == true
        }
      end

      def test_tops_for_src_bin_gen_pkg
        SK::ScopingLauncher.any_instance.expects(:local_scope_top).at_least_once.returns Pathname.new('/aaa/bbb/ccc/src')

        SK::ScopingLauncher.new.tap { |_app|
          assert_equal "/aaa/bbb/ccc/src", _app.srctop.to_s
          assert_equal "/aaa/bbb/ccc/bin", _app.bintop.to_s
          assert_equal "/aaa/bbb/ccc/gen", _app.gentop.to_s
          assert_equal "/aaa/bbb/ccc/pkg", _app.pkgtop.to_s
        }
      end

      def test_fails_if_nothing_in_path
        SK::ScopingLauncher.any_instance.expects(:setup)
        SK::ScopingLauncher.any_instance.expects(:invoke).never
        SK::ScopingLauncher.any_instance.expects(:find_in_path).with(anything).returns []
        SK::ScopingLauncher.any_instance.expects(:print_error).with instance_of(SK::NotInPathError)

        assert_raises SystemExit do
          SK::ScopingLauncher.new.tap { |_app|
            _app.verbose = true
            _app.start
          }
        end
      end

      def test_fails_if_only_self_in_path
        SK::ScopingLauncher.any_instance.expects(:setup)
        SK::ScopingLauncher.any_instance.expects(:invoke).never
        SK::ScopingLauncher.any_instance.expects(:find_in_path).with(anything).returns [ $0 ]
        SK::ScopingLauncher.any_instance.expects(:print_error).with instance_of(SK::NotInPathError)

        assert_raises SystemExit do
          SK::ScopingLauncher.new.tap { |_app|
            _app.verbose = true
            _app.start
          }
        end
      end

      def test_invokes_if_another_in_path
        SK::ScopingLauncher.any_instance.expects(:setup)
        SK::ScopingLauncher.any_instance.expects(:find_in_path).with(anything).returns [ Dir.pwd ]
        SK::ScopingLauncher.any_instance.expects(:print_error).never
        SK::ScopingLauncher.any_instance.expects(:command_line_arguments).returns %w{ aaa bbb ccc }

        Process.expects(:exec).with(Dir.pwd, 'aaa', 'bbb', 'ccc')
        $stderr.expects(:puts).never

        assert_nothing_raised do
          SK::ScopingLauncher.new.tap { |_app|
            _app.verbose = false
            _app.start
          }
        end
      end

      def test_invokes_if_another_in_path_with_command_printout_when_verbose
        SK::ScopingLauncher.any_instance.expects(:setup)
        SK::ScopingLauncher.any_instance.expects(:find_in_path).with(anything).returns [ Dir.pwd ]
        SK::ScopingLauncher.any_instance.expects(:print_error).never
        SK::ScopingLauncher.any_instance.expects(:command_line_arguments).returns %w{ aaa bbb ccc }

        Process.expects(:exec).with(Dir.pwd, 'aaa', 'bbb', 'ccc')
        $stderr.expects(:puts).with("### #{Dir.pwd} aaa bbb ccc")

        assert_nothing_raised do
          SK::ScopingLauncher.new.tap { |_app|
            _app.verbose = true
            _app.start
          }
        end
      end

      def setup
      end
    end
  end
end
