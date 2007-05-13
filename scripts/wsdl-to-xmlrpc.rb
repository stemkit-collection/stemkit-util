#!/usr/bin/env ruby
=begin
  Copyright (c) 2005, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

$:.concat ENV.to_hash['PATH'].to_s.split(':')

require 'tsc/application.rb'
require 'tsc/path.rb'

class Application < TSC::Application
  def initialize
    super('<WSDL URI>',
      [ '--test', 'Run internal tests', nil ]
    )
  end

  def start
    handle_errors {
      process_command_line

      throw :TEST if options.has_key?('test')
      raise TSC::UsageError unless ARGV.size == 1

      $:.push File.expand_path(File.dirname(__FILE__))

      require 'pp'
      require 'net/http'
      require 'rubygems'

      uri = URI.parse(ARGV.first)
      process(uri.scheme ? Net::HTTP.get(uri) : IO::readlines(uri.path).join)
    }
  end

  def process(data)
    require 'sk/rpc/wsdl.rb'
    wsdl = SK::RPC::Wsdl.new(data)

    pp wsdl.types
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

require 'test/unit'
require 'mocha'
require 'stubba'

class ApplicationTest < Test::Unit::TestCase
  def test_something
    flunk 'Not implemented'
  end

  def setup
    @app = Application.new
  end

  def teardown
    @app = nil
  end
end

exit Test::Unit::AutoRunner.run
