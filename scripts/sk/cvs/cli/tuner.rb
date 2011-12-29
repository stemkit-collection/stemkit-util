=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: EMC Gennady Bystritsky
=end

module SK
  module Cvs
    module Cli
      class Tuner
        attr_reader :app

        def initialize(app)
          @app = app
        end

        def extra_cvs_options
        end

        def check_option(option)
          option
        end

        def ready?
          true
        end
      end
    end
  end
end
