#!/usr/bin/env ruby
=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

$:.concat ENV['PATH'].to_s.split(File::PATH_SEPARATOR)
require 'sk/cli/tuning-launcher.rb'

class Application < SK::Cli::TuningLauncher
  protected
  #########

  def setup
    config.attribute(:root).tap { |_root|
      update_environment Hash[ :CVSROOT => _root ], :prefix => false, :upcase => true if _root
    }
  end

  def check_option(item)
    case item
      when 'status'
        configure_short_status if config.attribute('short-status') == true
        item

      when 'diff'
        configure_neat_diff if config.attribute('neat-diff') == true
        item

      when 'update'
        configure_neat_update if config.attribute('neat-update') == true
        item

      when 'classic-diff', 'clasic-update', 'classic-status', 'long-status'
        clear_tuner
        item.split('-').last

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
        nil
    end
  end

  private
  #######

  def config
    @config ||= super('.cvsrc', :uproot => true, :home => true)
  end

  def configure_short_status
    require 'sk/cli/cvs/status-tuner.rb'
    set_tuner SK::Cli::Cvs::StatusTuner.new(self)
  end

  def configure_neat_diff
    require 'sk/cli/cvs/diff-tuner.rb'
    set_tuner SK::Cli::Cvs::DiffTuner.new(self)
  end

  def configure_neat_update
    require 'sk/cli/cvs/update-tuner.rb'
    set_tuner SK::Cli::Cvs::UpdateTuner.new(self)
  end
end

Application.new.start
