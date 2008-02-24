#!/usr/bin/env ruby
# Copyright (c) 2005, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

$:.concat ENV['PATH'].to_s.split(File::PATH_SEPARATOR)

require 'tsc/application.rb'
require 'tsc/path.rb'

# This is a Subversion front-end that transforms its arguments as follows:
#   %r is replaced by a repository root found either in environment variable
#     SVN_ROOT or in the first file .svnrc found in the current directory or
#     any directory up to '/'  (YAML property 'Root').
#   %u is replaced by the current URL, handy in 'svn log %u' command.
#   %t is replaced by the top working directory.
#
class Application < TSC::Application
  def start
    handle_errors {
      require 'tsc/config-locator.rb'
      require 'yaml'
      require 'open3'

      if defined? SVN_ORIGINAL
        invoke SVN_ORIGINAL
      else
        commands = find_in_path(os.exe(script_name))
        commands.shift while commands.first == $0

        raise "No #{script_name.inspect} in PATH" if commands.empty?
        invoke commands.first
      end
    }
  end

  in_generator_context do |_content|
    directory, file = File.split(target)
    original = File.join(directory, 'original', file)

    _content << '#!' + figure_ruby_path
    _content << '$VERBOSE = nil'
    _content << TSC::PATH.current.front(File.dirname(figure_ruby_path)).to_ruby_eval
    _content << "SVN_ORIGINAL = #{original.inspect}"
    _content << IO.readlines(__FILE__).slice(1..-1)
  end

  private
  #######

  ROOT_INFO = 'Repository Root'
  URL_INFO = 'URL'

  def invoke(command)
    @command = find_original(command)
    setup_library_path_for(@command)

    puts "<Using #{@command}>" if verbose?

    exec command, *ARGV.map { |_item|
      _item.gsub(%r{%[rtu]}i) { |_match|
        case _match.downcase
          when '%r' then root
          when '%u' then url
          when '%t' then top
        end
      }
    }
  end

  def find_original(command)
    return command unless File.symlink?(command)
    find_original File.expand_path(File.readlink(command), File.dirname(command))
  end

  def setup_library_path_for(command, depth = 3)
    return if depth.zero?

    location = File.dirname(command)
    path = File.join(location, 'lib')
    
    if File.directory?(path)
      TSC::LD_LIBRARY_PATH.current.front(path).install
    else
      setup_library_path_for(location, depth - 1)
    end
  end

  def process_resource(directory, resource)
    resource_path = File.join directory, resource
    if File.exists? resource_path
      begin
        File.open(resource_path) { |_io|
          YAML.parse(_io).transform
        }
      rescue Exception => exception
        raise TSC::Error.new("Error parsing #{resource_path.inspect}", exception)
      end
    else
      process_resource(File.dirname(directory), resource) unless directory == '/'
    end
  end

  def config
    @config ||= begin 
      TSC::ConfigLocator.new('.svnrc').merge_all_above_with_personal
    end
  end

  def info(location)
    Open3.popen3("#{@command} info #{location}") do |_in, _out, _err|
      YAML.parse(_out).transform rescue Hash.new
    end
  end

  def dot_info
    @dot_info ||= info('.')
  end

  def url
    @url ||= dot_info[URL_INFO]
  end

  def root
    @root ||= begin
      ENV['SVN_ROOT'] or config.hash['Root'] or dot_info[ROOT_INFO] or begin
        raise 'Cannot figure out the root (check for .svnrc or working copy)'
      end
    end
  end

  def locate_top(*components)
    upper = [ '..', *components ]
    info(File.join(upper))[ROOT_INFO] == root ? locate_top(upper) : components
  end

  def top
    @top ||= begin
      File.join locate_top('.')
    end
  end
end

unless defined? Test::Unit::TestCase
  catch :TEST do
    Application.new.start
    exit 0
  end
end

require 'test/unit'

class ApplicationTest < Test::Unit::TestCase
  def test_nothing
  end

  def setup
    @app = Application.new
  end
end
