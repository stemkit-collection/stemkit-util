#!/usr/bin/env ruby
# Copyright (c) 2005, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.
#
# Author: Gennady Bystritsky

$:.concat ENV.to_hash['PATH'].to_s.split(File::PATH_SEPARATOR)

require 'tsc/application.rb'
require 'tsc/path.rb'

class Application < TSC::Application
  def initialize
    super { |_config|
      _config.arguments = '<class_name> ...'
      _config.options = [
        [ '--target', 'Specify language to bake', 'language', '-t' ],
        [ '--config', 'Use config file', 'yaml file', '-c' ],
        [ '--namespace', "Use namespace ('.' or '::' for hierarchy)", 'string', '-n' ],
        [ '--local', 'Enforce file creation in the current directory', nil, '-l' ],
        [ '--indent', 'Use so many spaces for indent (2 by default)', 'number', '-i' ],
        [ '--print', 'Print out instead of creating files', nil, '-p' ],
        [ '--mode', 'Set generation mode (e.g. test, app, etc.)', 'mode', '-m' ],
        [ '--force', 'Force file override', nil, '-f' ],
        [ '--list', 'List supported languages', nil, ],
        [ '--test', 'Run internal tests', nil ]
      ]
      _config.description = [
        "This utility performs code generation for c/c++ and ruby classes according",
        "to specification provided in a configuration file (src/config/new.yaml or",
        "~/.new.yaml)."
      ]
    }
  end

  def start
    handle_errors {
      process_command_line
      require 'tsc/dataset.rb'

      throw :TEST if options.test?
      require 'sk/lingo/bakery.rb'

      if options.list?
        puts "Supported languages: #{SK::Lingo::Baker.list.join(', ')}"
        exit
      end

      raise TSC::UsageError, 'Nothing to do' if ARGV.empty?

      TSC::Error.undo(Exception) do |_stack|
        bakery = SK::Lingo::Bakery.new options, script_location, _stack
        ARGV.each do |_item|
          bakery.make _item
        end
      end
    }
  end

  in_generator_context do |_content|
    _content << '#!' + figure_ruby_path
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
require 'stubba'

require 'sk/lingo/bakery.rb'

class ApplicationTest < Test::Unit::TestCase
  attr_reader :app

  def test_nothing
  end

  def setup
    @app = Application.new
  end
end
