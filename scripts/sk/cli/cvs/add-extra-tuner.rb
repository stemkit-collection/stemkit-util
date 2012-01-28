=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/cli/tuner.rb'

module SK
  module Cli
    module Cvs
      class AddExtraTuner < SK::Cli::Tuner
        def check_option(option)
          case option
            when '--folders'
              @folders = true

            else
              return super
          end

          nil
        end

        def process(io)
          io.each do |_line|
            case _line
              when %r{^[?]\s+(.*?)\s*$}
                item = $1
                next if item.split('/').any? { |_item|
                  _item == '.svn'
                }
                next if ::File.directory?(item) and folders? == false
                system('cvs', 'add', item) or exit $?.exitstatus
            end
          end
        end

        private
        #######

        def folders?
          @folders ? true : false
        end
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'mocha'

  module SK
    module Cli
      module Cvs
        class AddExtraTunerTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
