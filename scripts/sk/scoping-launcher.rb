=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'tsc/application.rb'
require 'sk/config/uproot-locator.rb'
require 'tsc/path.rb'

module SK
  class ScopingLauncher < TSC::Application
    class CollectingLocator < SK::Config::UprootLocator
      def find
        self.invoke self
        depot
      end

      def process(content, spot)
        depot << spot
      end

      def content(path)
        File.open(path) {}
        []
      end

      def depot
        @depot ||= []
      end
    end

    def start
      handle_errors {
        require 'rubygems'

        p top
      }
    end

    private
    #######

    def top
      @top ||= find_top 
    end

    def find_top
      Array(top_selectors).each { |_selector|
        CollectingLocator[_selector].find.tap { |_locations|
          return _locations.last unless _locations.empty?
        }
      }
      raise 'Scope top not found'
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
