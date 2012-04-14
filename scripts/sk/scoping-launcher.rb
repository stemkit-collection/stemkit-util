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
require 'sk/config/collector.rb'
require 'tsc/path.rb'
require 'tsc/errors.rb'

require 'forwardable'

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
    class Helper
      class << self
        def command_line_arguments(args)
          args
        end

        def launch(command, *args)
          Process.exec command, *args
        end

        def generate_path_sequence(path)
          return [ path ] if path == '.'
          generate_path_sequence(File.dirname(path)) + [ path ]
        end
      end
    end

    def start
      handle_errors {
        require 'rubygems'
        require 'pathname'

        setup

        prepare_arguments(ARGV).tap { |_args|
          (transparent? ? Helper : self).tap { |_invocator|
            with_string_array [ original_command, _invocator.command_line_arguments(_args) ] do |_cmdline|
              trace _cmdline.join(' ')
              populate_environment

              _invocator.launch *_cmdline
            end
          }
        }
      }
    end

    def update_environment(env, options = {})
      environments << PropertiesNormalizer.new(script_name, options).normalize(env)
    end

    def local_scope_top
      @local_scope_top ||= begin
        figure_scope_top('local', current_location, local_scope_selectors).tap { |_location, _item|
          top = Pathname.new _location
          @local_scope_trigger = top.join(_item)

          break top
        }
      end
    end

    def scope_descriptors_to_top(*args)
      @scope_descriptors_to_top ||= begin
        Helper.generate_path_sequence(path_to_local_scope_top).map { |_path|
          args.map { |_name|
            descriptor = File.join(_path, _name.to_s)
            break descriptor if exists_in_current?(descriptor)
          }
        }.flatten.compact
      end
    end

    def exists_in_current?(filename)
      current_location.join(filename.to_s).exist?
    end

    def path_to_local_scope_top
      local_scope_top_path_info.last
    end

    def path_from_local_scope_top
      local_scope_top_path_info.first
    end

    def local_scope_trigger
      local_scope_top
      @local_scope_trigger
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
      @global_scope_top ||= begin
        figure_scope_top('global', script_location, global_scope_selectors).tap { |_location, _item|
          top = Pathname.new _location
          @global_scope_trigger = top.join(_item)

          break top
        }
      end
    end

    def global_scope_trigger
      global_scope_top
      @global_scope_trigger
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

    def config(name, options = {})
      SK::Config::Collector.new(self).collect(name, options)
    end

    def config_attributes(location)
      ConfigAttributes.new(self, location)
    end

    def transparent=(state)
      @transparent = state ? true : false
    end

    def transparent?
      loop do
        case @app_transparent
          when nil
            case ENV[[ :sk, script_name, :transparent ].join('_').upcase]
              when %r{^(true)|(yes)|(on)$}i
                @app_transparent = true

              when %r{^(false)|(no)|(off)$}i
                @app_transparent = false

              else
                @app_transparent = :none
            end

          when :none
            return @transparent ? true : false

          else
            return @app_transparent
        end
      end
    end

    protected
    #########

    def setup
      raise TSC::NotImplementedError, :setup
    end

    def original_command
      @original_command ||= begin
        find_in_path(os.exe(script_name)).tap { |_commands|
          _commands.shift while myself?(_commands.first)
          raise NotInPathError, script_name if _commands.empty?

          break _commands.first
        }
      end
    end

    def command_line_arguments(args)
      Helper.command_line_arguments(args)
    end

    def prepare_arguments(args)
      args
    end

    def local_scope_selectors
    end

    def global_scope_selectors
    end

    def launch(command, *args)
      Helper.launch(command, *args)
    end

    private
    #######

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
          @properties[upcase(prefix(_key.to_s))] = _value.to_s
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

    class ConfigAttributes
      attr_reader :location

      extend Forwardable
      def_delegators :@master, :local_scope_top, :global_scope_top, :srctop, :bintop, :pkgtop, :gentop

      def initialize(master, location)
        @master, @location = master, location
      end
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

    def myself?(path)
      program_file_realpath == Pathname.new(path).realpath if path
    end

    def program_file_realpath
      @program_file_realpath ||= Pathname.new($0).realpath
    end

    def figure_scope_top(label, origin, selectors)
      with_normalized_array selectors do |_selectors|
        _selectors.each do |_selector|
          SK::Config::UprootPathCollector.new(:item => _selector, :spot => origin.to_s).locations.tap { |_locations|
            return [ _locations.last, _selector ] unless _locations.empty?
          }
        end
        raise SK::SelectableScopeError, [ label, _selectors ]
      end
    end

    def local_scope_top_path_info
      @local_scope_top_path_info ||= begin
        current_location.to_s.scan(%r{^(#{Regexp.quote(local_scope_top.to_s)})(?:[/]*)(.*)$}).flatten.tap { |_result|
          raise "Wrong path info" unless _result
          break [ '.', '.' ] if _result.last.empty?
          break [ _result.last, ([ '..' ] * _result.last.count('/').next).join('/') ]
        }
      end
    end

    def current_location
      @current_location ||= Pathname.new(Dir.pwd)
    end

    def environments
      @environments ||= []
    end

    def populate_environment
      return if environments.empty?

      environments.each do |_environment|
        _environment.each_pair do |_key, _value|
          trace "#{_key} => #{_value.inspect}"
          ENV[_key] = _value
        end
      end
    end

    def with_normalized_array(array)
      yield Array(array).flatten.compact
    end

    def with_string_array(array)
      yield Array(array).flatten.map { |_item|
        next nil if _item.nil?
        _item.to_s.tap { |_string|
          break nil if _string.empty?
        }
      }.compact
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    class ScopingLauncherTest < Test::Unit::TestCase
      def test_nothing
      end

      def setup
      end
    end
  end
end
