=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

module SK
  module Lingo
    module Ruby
      module Ingredients
        def content
          lines ruby['content']
        end

        def shebang
          lines ruby['shebang']
        end
      end
    end
  end
end

