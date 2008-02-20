=begin
  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
  
  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.
  
  Author: Gennady Bystritsky
=end

require 'sk/lingo/baker.rb'

module SK
  module Lingo
    module C
      class Baker < SK::Lingo::Baker
        def accept(item)
          case item.extension
            when 'c'
              c name, namespace, extension

            else
              return false
          end

          true
        end

        def c(name, namespace, extension)
          save "#{name}.#{extension}", name, namespace, [
            make_c_comments(make_copyright_notice),
            prepend_newline_if(make_namespace(namespace))
          ]
        end

      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  require 'mocha'
  require 'stubba'
  
  module SK
    module Lingo
      module C
        class BakerTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end

