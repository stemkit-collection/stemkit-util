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

module SK
  class EnvPropagator
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def load
      raise TSC::NotImplementedError, SK::Ruby::Spot[binding].full_method_name
    end

    def update(env, options = {})
      environments << PropertiesNormalizer.new(name, options).normalize(env)
    end

    def populate
      return if environments.empty?

      environments.each do |_environment|
        _environment.each_pair do |_key, _value|
          yield _key, _value if block_given?
          ENV[_key] = _value
        end
      end
    end

    private
    #######

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
    class EnvPropagatorTest < Test::Unit::TestCase
      def setup
      end
    end
  end
end
