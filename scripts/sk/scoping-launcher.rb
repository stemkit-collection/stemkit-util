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

module SK
  class ScopingLauncher < TSC::Application
    def start
      handle_errors {
        require 'rubygems'
        require 'pathname'

        setup
      }
    end

    def local_scope_top
      @local_scope_top ||= Pathname.new(figure_local_scope_top)
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

    def figure_local_scope_top
      Array(local_scope_selectors).each { |_selector|
        SK::Config::UprootPathCollector.new(:item => _selector, :spot => '.').locations.tap { |_locations|
          return _locations.last unless _locations.empty?
        }
      }
      raise 'Local scope top not found'
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    class ScopingLauncherTest < Test::Unit::TestCase
      def setup
      end
    end
  end
end
