#!/usr/bin/env ruby
# vim: set sw=2:
# Copyright (c) 2005, Gennady Bystritsky <bystr@mac.com>
#
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

$:.concat ENV.to_hash['PATH'].to_s.split(File::PATH_SEPARATOR)
require 'sk/cli/tuning-launcher.rb'

# This is a Subversion front-end that transforms its arguments as follows:
#   %r is replaced by a repository root found either in environment variable
#     SVN_ROOT or in the first file .svnrc found in the current directory or
#     any directory up to '/'  (YAML property 'Root').
#   %u is replaced by the current URL, handy in 'svn log %u' command.
#   %t is replaced by the top working directory.
#
class Application < SK::Cli::TuningLauncher
  in_generator_context do |_content|
    file = File.basename(target)
    directory = File.join(self.class.installation_top, 'bin')
    original = File.join(directory, 'originals', file)

    _content << '#!/usr/bin/env ' + figure_ruby_path
    _content << TSC::PATH.current.front(directory).to_ruby_eval
    _content << "ORIGINAL = #{original.inspect}"
    _content << IO.readlines(__FILE__).slice(1..-1)
  end

  protected
  #########

  ROOT_INFO = 'Repository Root'
  URL_INFO = 'URL'

  def setup
    require 'yaml'
    require 'open3'
  end

  def original_command
    defined?(ORIGINAL) ? ORIGINAL : super
  end

  def check_option(item)
    case item
      when '-S'
        '--stop-on-copy'

      when '-I', '--no-ignore'
        tuner.check_option('--no-ignore')

      when '--xml-local-time'
        require 'sk/cli/svn/local-time-tuner.rb'
        set_tuner SK::Cli::Svn::LocalTimeTuner.new(self)
        '--xml'

      when 'remove-missing', 'rm-missing', 'rm-gone'
        configure_remove_missing
        'status'

      when 'add-extra'
        configure_add_extra
        'status'

      when 'status', 'ss', 'su', 'si'
        configure_status_no_cvs if config.attribute('status-no-cvs') == true
        [ 'status',
          ('-u' if item == 'su'),
          (tuner.check_option('--no-ignore') if item == 'si')
        ]

      when 'diff', 'dd', 'ds', 'di'
        configure_diff_no_cvs if config.attribute('diff-no-cvs') == true
        [ 'diff',
          ('--summarize' if item == 'ds'),
          (tuner.check_option('--no-ignore') if item == 'di')
        ]

      when 'log', 'll'
        configure_log_no_cvs if config.attribute('log-no-cvs') == true
        [ 'log', ('--stop-on-copy' if item == 'll') ]

      when 'uu'
        'update'

      when 'status-no-cvs'
        configure_status_no_cvs
        'status'

      when 'diff-no-cvs'
        configure_diff_no_cvs
        'diff'

      when 'log-no-cvs'
        configure_log_no_cvs
        'log'

      when 'cvs-diff'
        configure_cvs_diff
        'diff'

      else
        item.gsub(%r{%[rtu]}i) { |_match|
          case _match.downcase
            when '%r' then root
            when '%u' then url
            when '%t' then top
          end
        }
    end
  end

  private
  #######

  def configure_status_no_cvs
    require 'sk/cli/svn/cvs-entries-status-tuner.rb'
    set_tuner SK::Cli::Svn::CvsEntriesStatusTuner.new(self)
  end

  def configure_remove_missing
    require 'sk/cli/svn/remove-missing-tuner.rb'
    set_tuner SK::Cli::Svn::RemoveMissingTuner.new(self)
  end

  def configure_add_extra
    require 'sk/cli/svn/add-extra-tuner.rb'
    set_tuner SK::Cli::Svn::AddExtraTuner.new(self)
  end

  def configure_diff_no_cvs
    require 'sk/cli/svn/cvs-entries-diff-tuner.rb'
    set_tuner SK::Cli::Svn::CvsEntriesDiffTuner.new(self)
  end

  def configure_log_no_cvs
    require 'sk/cli/svn/cvs-entries-log-tuner.rb'
    set_tuner SK::Cli::Svn::CvsEntriesLogTuner.new(self)
  end

  def configure_cvs_diff
    require 'sk/cli/svn/cvs-diff-format-tuner.rb'
    set_tuner SK::Cli::Svn::CvsDiffFormatTuner.new(self)
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
