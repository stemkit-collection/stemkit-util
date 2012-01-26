=begin
  vim: sw=2:
  Copyright (c) 2011, Gennady Bystritsky <bystr@mac.com>

  Distributed under the MIT Licence.
  This is free software. See 'LICENSE' for details.
  You must read and accept the license prior to use.

  Author: Gennady Bystritsky
=end

require 'sk/cli/tuner.rb'
require 'sk/cli/cvs/file.rb'

module SK
  module Cli
    module Cvs
      class RemoveMissingTuner < SK::Cli::Tuner
        def process(io)
          io.each do |_line|
            case _line
              when %r{^cvs\s+status:\s+Examining\s+(.*?)\s*$}
                set_folder $1

              when %r{^File:\s+(.*?)\s+Status:\s+(.*?)\s*$}
                Cvs::File.new($1, folder, $2).tap do |_file|
                  system('cvs', 'rm', _file.path.to_s) if _file.missing?
                end
            end
          end
        end

        private
        #######

        def set_folder(folder)
          @folder = Pathname.new(folder)
        end

        def folder
          @folder or raise 'No folder information encountered'
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
        class RemoveMissingTunerTest < Test::Unit::TestCase
          def test_nothing
          end

          def setup
          end
        end
      end
    end
  end
end
