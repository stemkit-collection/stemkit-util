# vim: set sw=2:
=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/cpp/baker.rb'

module SK
  module Lingo
    module Cc
      class Baker < SK::Lingo::Cpp::Baker
        def generate_default_fileset(item)
          header item, :h, 'h'
          body item, :cc, 'cc'
        end
      end
    end
  end
end

