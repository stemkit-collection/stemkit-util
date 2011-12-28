#!/usr/bin/env ruby
=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

ARGV.tap { |_first, *_rest|
  break unless _first == 'join-output'

  $stderr.reopen($stdout)
  Kernel.exec *_rest
}

$:.concat ENV['PATH'].to_s.split(File::PATH_SEPARATOR)
require 'sk/scoping-launcher.rb'

class Application < SK::ScopingLauncher
  protected
  #########

  class NoopTuner
    def check_option(option)
      option
    end

    def ready?
      false
    end
  end

  def setup
    config.attribute(:root).tap { |_root|
      update_environment Hash[ :CVSROOT => _root ], :prefix => false, :upcase => true if _root
    }
  end

  def command_line_arguments(args)
    args.map { |_item|
      case _item
        when 'status'
          configure_short_status if config.attribute('short-status') == true
          _item

        when 'diff'
          configure_neat_diff if config.attribute('neat-diff') == true
          _item

        when 'update'
          configure_neat_update if config.attribute('neat-update') == true
          _item

        when 'classic-diff', 'clasic-update', 'classic-status', 'long-status'
          @tuner = nil
          _item.split('-').last

        when 'short-status'
          configure_short_status
          'status'

        when 'neat-diff'
          configure_neat_diff
          'diff'

        when 'neat-update'
          configure_neat_update
          'update'

        else
          tuner.check_option(_item)
      end
    }
  end

  def launch(command, *args)
    return super(command, *args) unless tuner.ready?
    require 'open3'

    Open3.popen3($0, 'join-output', command, *args) do |_in, _out, |
      tuner.process _out
    end
  end

  private
  #######

  def config
    @config ||= super('.cvsrc', :uproot => true, :home => true)
  end

  def tuner
    @tuner ||= NoopTuner.new
  end

  def configure_short_status
    require 'sk/cvs/cli/status-tuner.rb'
    @tuner = SK::Cvs::Cli::StatusTuner.new(self)
  end

  def configure_neat_diff
    require 'sk/cvs/cli/diff-tuner.rb'
    @tuner = SK::Cvs::Cli::DiffTuner.new(self)
  end

  def configure_neat_update
    require 'sk/cvs/cli/update-tuner.rb'
    @tuner = SK::Cvs::Cli::UpdateTuner.new(self)
  end

  public
  ######

  def output_info(info)
    $stdout.puts info
  end

  def output_errors(*args)
    $stderr.puts *args.flatten.compact
  end
end

Application.new.start
