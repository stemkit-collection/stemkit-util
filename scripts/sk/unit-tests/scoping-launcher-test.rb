=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/scoping-launcher.rb'

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
        assert_equal path, _app.local_scope_trigger.to_s
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

    def test_invokes_if_another_in_path_with_command_and_environment_printout_when_verbose
      SK::ScopingLauncher.any_instance.expects(:setup)
      SK::ScopingLauncher.any_instance.expects(:find_in_path).with(anything).returns [ Dir.pwd ]
      SK::ScopingLauncher.any_instance.expects(:print_error).never
      SK::ScopingLauncher.any_instance.expects(:command_line_arguments).returns %w{ aaa bbb ccc }
      SK::ScopingLauncher.any_instance.expects(:script_name).at_least_once.returns "bca"

      Process.expects(:exec).with(Dir.pwd, 'aaa', 'bbb', 'ccc')
      $stderr.expects(:puts).with("### #{Dir.pwd} aaa bbb ccc")
      $stderr.expects(:puts).with('### SK_BCA_V1 => "333"')
      $stderr.expects(:puts).with('### SK_BCA_V2 => "456"')

      assert_nothing_raised do
        SK::ScopingLauncher.new.tap { |_app|
          _app.verbose = true
          _app.environment.update :v1 => 333, :v2 => 456

          _app.start
        }
      end

      assert_equal "333", ENV['SK_BCA_V1']
      assert_equal "456", ENV['SK_BCA_V2']
    end

    def test_path_to_and_from_local_scope_top_in_the_middle
      SK::ScopingLauncher.any_instance.expects(:local_scope_top).at_least_once.returns "/a/b/c"
      Dir.expects(:pwd).at_least_once.returns "/a/b/c/d/e"

      SK::ScopingLauncher.new.tap { |_app|
        assert_equal '../..', _app.path_to_local_scope_top
        assert_equal 'd/e', _app.path_from_local_scope_top
      }
    end

    def test_path_to_and_from_local_scope_top_at_the_end
      SK::ScopingLauncher.any_instance.expects(:local_scope_top).at_least_once.returns "/a/b/c"
      Dir.expects(:pwd).at_least_once.returns "/a/b/c"

      SK::ScopingLauncher.new.tap { |_app|
        assert_equal '.', _app.path_to_local_scope_top
        assert_equal '.', _app.path_from_local_scope_top
      }
    end

    def test_path_to_and_from_local_scope_top_in_the_root
      SK::ScopingLauncher.any_instance.expects(:local_scope_top).at_least_once.returns "/"
      Dir.expects(:pwd).at_least_once.returns "/a/b/c"

      SK::ScopingLauncher.new.tap { |_app|
        assert_equal '../../..', _app.path_to_local_scope_top
        assert_equal 'a/b/c', _app.path_from_local_scope_top
      }
    end

    def test_generate
      assert_equal [ '.' ], SK::ScopingLauncher::Helper.generate_path_sequence('.')
      assert_equal [ '.', '..' ], SK::ScopingLauncher::Helper.generate_path_sequence('..')
      assert_equal [ '.', '..', '../..' ], SK::ScopingLauncher::Helper.generate_path_sequence('../..')
      assert_equal [ '.', '..', '../..', '../../..' ], SK::ScopingLauncher::Helper.generate_path_sequence('../../..')
    end

    def test_scope_descriptors_from_top
      SK::ScopingLauncher.new.tap { |_app|
        _app.expects(:path_to_local_scope_top).at_least_once.returns "../../.."
        _app.expects(:exists_in_current?).with(anything).at_least_once.returns false
        _app.expects(:exists_in_current?).with('./zzz').returns true
        _app.expects(:exists_in_current?).with('../../../uuu').returns true
        _app.expects(:exists_in_current?).with('../../../zzz').at_most_once.returns true

        assert_equal [ './zzz', '../../../uuu' ], _app.scope_descriptors_to_top('uuu', 'zzz')
      }
    end

    def test_app_can_set_transparent
      SK::ScopingLauncher.new.tap { |_app|
        _app.expects(:script_name).with.at_least_once.returns('app')

        assert_equal false, _app.transparent?
        _app.transparent = true
        assert_equal true, _app.transparent?
      }
    end

    def test_env_overrides_transparent
      SK::ScopingLauncher.new.tap { |_app|
        _app.expects(:script_name).with.at_least_once.returns('app')
        _app.transparent = false

        ENV['SK_APP_TRANSPARENT'] = 'True'
        assert_equal true, _app.transparent?
      }

      SK::ScopingLauncher.new.tap { |_app|
        _app.expects(:script_name).with.at_least_once.returns('app')
        _app.transparent = true

        ENV['SK_APP_TRANSPARENT'] = 'No'
        assert_equal false, _app.transparent?
      }
    end

    def setup
      ENV.delete('SK_APP_TRANSPARENT')
    end
  end
end
