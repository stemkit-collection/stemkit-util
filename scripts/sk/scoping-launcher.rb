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

        p local_scope_top
      }
    end

    def local_scope_top
      @local_scope_top ||= figure_local_scope_top 
    end

    protected
    #########

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
