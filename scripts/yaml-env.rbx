#!/usr/bin/env ruby
=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
=end

$:.concat ENV.to_hash['PATH'].to_s.split(File::PATH_SEPARATOR)

require 'tsc/application.rb'
require 'tsc/path.rb'
require 'tsc/config.rb'

class Application < TSC::Application
  def initialize
    super { |_config|
      _config.arguments = '[ <command> [ <command options> ... ] ]'
      _config.options = [
        [ '--prefix', 'Prefix for variables', 'string', '-p' ],
        [ '--config', 'YAML config file', 'path', '-c' ],
        [ '--key', 'Top level attribute key', 'key', '-k', '-T' ],
        [ '--upcase', 'Upcase all characters', nil, '-u' ],
        [ '--export', 'Generate output suitable for eval', nil, '-e' ],
        [ '--batch', 'Generate output suitable for DOS batch files', nil, '-b' ],
        [ '--test', 'Run internal tests', nil ]
      ]
      _config.description = [
        "This utility generates shell variable assignments",
        "from the content of a yaml config file."
      ]
    }
  end

  def start
    handle_errors {
      process_command_line true
      require 'rubygems'

      case
        when options.test?
          throw :TEST

        when ARGV.empty?
          print_env

        else
          exec_with_env
      end
    }
  end

  def print_env
    puts *config.map { |_name, _value|
      make_env_entry(make_name(_name), _value.to_s).compact.join(' ')
    }
  end

  def make_env_entry(name, value)
    [
      (options.batch? ? "set #{name}=#{value}" : "#{name}=#{value.inspect}"),
      ("export #{name};" if options.export?)
    ]
  end

  def exec_with_env
    config.each do |_name, _value|
      ENV[make_name(_name)] = _value.to_s
    end

    exec *ARGV
  end

  def config_file
    options.config or raise TSC::MissingResourceError, 'config file'
  end

  def config
    @config ||= TSC::Config.parse(config_file).hash(*options.key_list)
  end

  def make_name(item)
    [ options.prefix_list, item ].flatten.compact.join('_').tr('-', '_').send(options.upcase? ? 'upcase' : 'to_s')
  end

  in_generator_context do |_content|
    _content << '#!' + figure_ruby_path
    _content << '$VERBOSE = nil'
    _content << TSC::PATH.current.front(File.dirname(figure_ruby_path)).to_ruby_eval
    _content << IO.readlines(__FILE__).slice(1..-1)
  end
end

unless defined? Test::Unit::TestCase
  catch :TEST do
    Application.new.start
    exit 0
  end
end

require 'rubygems'
require 'test/unit'
require 'mocha'

class ApplicationTest < Test::Unit::TestCase
  attr_reader :app

  def test_nothing
  end

  def setup
    @app = Application.new
  end
end
