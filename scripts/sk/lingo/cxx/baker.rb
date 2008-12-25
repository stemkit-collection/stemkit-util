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
    module Cxx
      class Baker < SK::Lingo::Cpp::Baker
        def accept_by_extension(item)
          case item.extension
            when 'hxx'
              proc {
                header item, :hxx
              }

            when 'cxx'
              proc {
                header item, :cxx
              }
          end
        end

        def accept_default(item)
          proc {
            header item, :hxx, 'hxx'
            header item, :cxx, 'cxx'
          }
        end
      end
    end
  end
end

