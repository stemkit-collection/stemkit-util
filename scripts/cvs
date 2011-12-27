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
require 'sk/scoping-launcher.rb'

class Application < SK::ScopingLauncher
  protected
  #########

  def setup
    config('.cvsrc', :uproot => true, :home => true).tap { |_config|
      _config.attribute(:root).tap { |_root|
        update_environment Hash[ :CVSROOT => _root ], :prefix => false, :upcase => true if _root
      }
    }
  end

  def launch(command, *args)
    super
  end
end

Application.new.start
