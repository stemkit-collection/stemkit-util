#!/usr/bin/env ruby
=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky <bystr@mac.com>
=end

$:.concat ENV['PATH'].to_s.split(File::PATH_SEPARATOR)

require 'tsc/application.rb'
require 'tsc/path.rb'

class Application < TSC::Application
  def initialize
    super { |_config|
      _config.arguments = ''
      _config.options = [
        [ '--test', 'Run internal tests', nil ]
      ]
      _config.description = [
        "Platform id guessing utility"
      ]
    }
  end

  def start
    handle_errors {
      process_command_line
      require 'rubygems'
      require 'tsc/platform.rb'

      throw :TEST if options.test?
      raise TSC::UsageError unless ARGV.empty?

      puts TSC::Platform.current.name
    }
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
