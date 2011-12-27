#!/usr/bin/env ruby
# vim: set sw=2:
# Copyright (c) 2005, Gennady Bystritsky <bystr@mac.com>
#
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

$:.concat ENV['PATH'].to_s.split(File::PATH_SEPARATOR)

require 'sk/scoping-launcher.rb'
require 'tsc/path.rb'

# This is a Subversion front-end that transforms its arguments as follows:
#   %r is replaced by a repository root found either in environment variable
#     SVN_ROOT or in the first file .svnrc found in the current directory or
#     any directory up to '/'  (YAML property 'Root').
#   %u is replaced by the current URL, handy in 'svn log %u' command.
#   %t is replaced by the top working directory.
#
class Application < SK::ScopingLauncher
  in_generator_context do |_content|
    file = File.basename(target)
    directory = File.join(self.class.installation_top, 'bin')
    original = File.join(directory, 'originals', file)

    _content << '#!/usr/bin/env ' + figure_ruby_path
    _content << TSC::PATH.current.front(directory).to_ruby_eval
    _content << "SVN_ORIGINAL = #{original.inspect}"
    _content << IO.readlines(__FILE__).slice(1..-1)
  end

  protected
  #########

  ROOT_INFO = 'Repository Root'
  URL_INFO = 'URL'

  def setup
    require 'yaml'
    require 'open3'
    require 'time'
  end

  def original_command
    defined?(SVN_ORIGINAL) ? SVN_ORIGINAL : super
  end

  def command_line_arguments(args)
    args.map { |_item|
      case _item
        when '-S'
          '--stop-on-copy'

        when '-I'
          '--no-ignore'

        when '--xml-local-time'
          @translate_xml_time = true
          '--xml'

        else
          _item.gsub(%r{%[rtu]}i) { |_match|
            case _match.downcase
              when '%r' then root
              when '%u' then url
              when '%t' then top
            end
          }
      end
    }
  end

  def launch(command, *args)
    return super(command, *args) unless @translate_xml_time

    Open3.popen3(command, *args) { |_in, _out, _err|
      _err.readlines.each do |_line|
        $stderr.puts _line
      end

      $stdout.puts translate_xml_time(_out.readlines.join)
    }
  end

  private
  #######

  def translate_xml_time(line)
    line.gsub(%r{(<date>)(.*)T(.*)[.](.*)Z(</date>)}) { |*_match|
      $1 + gmt_to_local($2, $3, $4) + $5
    }
  end

  def gmt_to_local(date, time, ms)
    Time.parse("#{date} #{time} GMT").strftime("%Y-%m-%dT%H:%M:%S.#{ms}Z%Z")
  end

  def config
    @config ||= super('.svnrc', :uproot => true, :home => true)
  end

  def info(location)
    Open3.popen3("#{original_command} info #{location}") do |_in, _out, _err|
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
      ENV['SVN_ROOT'] or config.attribute(:root) or dot_info[ROOT_INFO] or begin
        raise 'Cannot figure out the root (check for .svnrc or working copy)'
      end
    end
  end

  def locate_top(*components)
    upper = [ '..', *components ]
    info(File.join(upper))[ROOT_INFO] ? locate_top(upper) : components
  end

  def top
    @top ||= begin
      File.join locate_top('.')
    end
  end
end

Application.new.start
