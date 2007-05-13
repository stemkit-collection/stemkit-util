=begin
  Copyright (c) 2007, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
=end

require 'sk/rpc/builder.rb'

module SK
  module RPC
    module Java
      class Builder < SK::RPC::Builder
        def make_xmlrpc(destination)
          pp wsdl.service
          pp wsdl.endpoint
          pp wsdl.actions
        end
      end
    end
  end
end
