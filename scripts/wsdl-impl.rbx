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
      [ '--language', 'Specifies output language', 'language', '-l' ],
      [ '--protocol', 'Specifies ouptut protocol', 'protocol', '-p' ],
      [ '--output', 'Specifies output directory', 'directory', '-o' ],
      [ '--namespace', 'Specifies a namespace for generated code', 'namespace', '-n' ],
      [ '--test', 'Runs internal tests', nil ]
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

    builder = builder_factory.new SK::RPC::Wsdl.new(data), namespace
    method_name = "make_#{protocol}"

    unless builder.respond_to? method_name
      raise "Protocol #{protocol.inspect} not supported for language #{language.inspect}"
    end

    builder.send method_name, destination
  end

  def builder_factory
    begin
      require "sk/rpc/#{language}/builder.rb"
      "SK::RPC::#{language.capitalize}::Builder".split('::').inject(Module) { |_module, _name|
        _module.const_get(_name)
      }
    rescue StandardError, LoadError
      raise "Lanuguage #{language.inspect} not supported"
    end
  end

  def destination
    @destination ||= (options['output'] || Dir.pwd)
  end

  def language
    @language ||= begin
      item = options['language'] or raise 'Output language not specified'
      item = item.strip.downcase

      raise "Wrong language specification #{language.inspect}" unless item =~ %r{^\w+$}

      item
    end
  end

  def protocol
    @protocol ||= begin
      item = options['protocol'] or raise 'Output protocol not specified'
      item = item.strip.downcase

      raise "Wrong protocol specification #{protocol.inspect}" unless item =~ %r{^\w+$}

      item
    end
  end

  def namespace
    @namespace ||= options['namespace'].to_s.split(%r{(?:::)|(?:[.])}).map { |_item|
      _item.strip
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

require 'test/unit'
require 'mocha'

class ApplicationTest < Test::Unit::TestCase
  def test_nothing
  end

  def setup
    @app = Application.new
  end
end
