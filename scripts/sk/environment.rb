=begin
  vim: sw=2:
  Copyright (c) 2014 Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Bystritsky, Gennady
=end

require 'tsc/dataset'
require 'tsc/errors'
require 'sk/ruby/spot'

require 'sk/config/provider'
require 'sk/config/collector'

module SK
  class Environment
    include SK::Config::Provider
    attr_reader :label

    # @param [String] label
    #   A label for paremeter name transformation.
    #
    # @param [SK::Config::Provider] provider
    #   A config provider.
    #
    def initialize(label, provider = self)
      @label, @provider = label, provider
    end

    def load_general_properties
      load_properties :general
    end

    def load_build_properties
      load_properties :make, :build
    end

    def update(env, options = {})
      self.tap do
        environments << PropertiesNormalizer.new(label, options).normalize(env)
      end
    end

    def populate
      self.tap do
        next if environments.empty?

        environments.each do |_environment|
          _environment.each_pair do |_key, _value|
            yield _key, _value if block_given?
            ENV[_key] = _value
          end
        end
      end
    end

    def config(name, options = {})
      SK::Config::Collector.new.collect(name, options)
    end

    private
    #######

    def load_properties(area, *extras)
      self.tap do
        "SK_ENVRC_#{area.to_s.upcase}".tap do |_trigger|
          next if ENV[_trigger] == 'off'

          update resource.properties(area, *extras), :prefix => false, :upcase => false
          ENV[_trigger] = 'off'
        end
      end
    end

    def resource
      @resource ||= @provider.config('.envrc', :uproot => true, :home => true)
    end

    def environments
      @environments ||= []
    end

    class PropertiesNormalizer
      DEFAULTS = {
        :prefix => true,
        :upcase => true
      }
      attr_reader :options, :app

      def initialize(app, options)
        @app = app
        @options = TSC::Dataset.new(DEFAULTS).update(options)
        @properties = {}
      end

      def normalize(properties)
        properties.each_pair do |_key, _value|
          @properties[upcase(prefix(_key.to_s).gsub(%r{[.\-\:/]}, '_'))] = _value.to_s
        end

        @properties
      end

      private
      #######

      def upcase(string)
        @options.upcase ? string.upcase : string
      end

      def prefix(string)
        return string unless options.prefix
        [ (options.prefix == true ? [ 'sk', app ] : options.prefix), string ].join('_')
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    class EnvironmentTest < Test::Unit::TestCase
      def setup
      end
    end
  end
end
